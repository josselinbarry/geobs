## VERSION FINALISEE AU 20230627
## En cours d'ajout sur la partie analytique

# Library ----
#library(plyr)
library(tidyverse)
# library(lubridate)
# library(RcppRoll)
# library(DT)
# library(readxl)
# library(dbplyr)
# library(RPostgreSQL)
# library(rsdmx)
library(sf)
#library(stringi)

source(file = "R/functions.R")

# Chargement données obstacles ----

## BDOE ----

bdoe <- data.table::fread(file = "data/export_de_base_20230417.csv")


## ROE par bassin ----

roe_lb <- data.table::fread(file = "data/lb_temp20230402.csv",
                            encoding = "Latin-1",
                            colClasses = c("date_creation" = "character"))

roe_sn <- data.table::fread(file = "data/sn_temp20230402.csv",
                            encoding = "Latin-1",
                            colClasses = c("date_creation" = "character"))


## Fusionner les ROE par bassin ---- 

roe_lb_sn <- dplyr::bind_rows(roe_lb, roe_sn)


## Basculer le ROE en sf_geom ----

roe_geom <- roe_lb_sn %>% 
  st_as_sf(coords = c("x_l93", "y_l93"), remove = FALSE, crs = 2154) 


## Jointure ROE et BDOE et sélection des obstacles BZH et PDL----

bdroe_dr2 <- roe_geom %>% 
  dplyr::left_join(bdoe, 
                   by = c("identifiant_roe" = "cdobstecou")) %>%
  dplyr::filter(dept_code %in% c('22', '29', '35', '56', '44', '49', '53', '72', '85'))



# Import des données de contexte ----

liste2 <- 
  sf::read_sf(dsn = "data/Liste2_LB_2018_holobiotiques.shp")

tampon_liste2 <-
  sf::st_buffer(liste2, dist = 50)

liste1 <- 
  sf::read_sf(dsn = "data/Liste1_214.17.shp")

tampon_liste1 <-
  sf::st_buffer(liste1, dist = 50)

ouvrages_prioritaires <-
  data.table::fread(file = "data/20230601_Ouv_prioritaires BZH_PDL.csv")

zap_anguille <-
  sf::read_sf(dsn = "data/zap_anguille.gpkg")

masse_eau <-
  sf::read_sf(dsn = "data/BVSpeMasseDEauSurface_edl2019.shp")

sage <-
  sf::read_sf(dsn = "data/sage_2016_DIR2.shp")

# Mise à jour Ouvrages prioritaires ----

bdroe_dr2 <- bdroe_dr2 %>% 
  dplyr::left_join(ouvrages_prioritaires, 
                   by = c("identifiant_roe" = "identifiant_roe"))%>%
  mutate(bdroe_dr2, ouvrage_prio = case_when(
    ouvrage_prio == "oui" ~ 'Oui',
    ouvrage_prio == "" ~ 'Non',
    is.na(ouvrage_prio) ~ 'Non'))


# Mise à jour spatiale ----

maj_roe <- bdroe_dr2 %>%
  dplyr::select(
    identifiant_roe,
    statut_nom,
    etat_nom,
    type_nom,
    fpi_nom1,
    fpi_nom2,
    fpi_nom3,
    fpi_nom4,
    fpi_nom5,
    hauteur_chute_etiage,
    hauteur_chute_etiage_classe,
    ouv_hauteur_chute_1,
    ouv_hauteur_chute_2,
    ouv_hauteur_chute_3,
    ouv_hauteur_chute_4,
    ouv_hauteur_chute_5,
    hauteur_chute_ICE,
    ouv_arasement,
    ouv_derasement,
    mesure_corrective_devalaison_equipement,
    mesure_corrective_montaison_equipement,
    avis_technique_global,
    classement_liste_1,
    classement_liste_2,
    especes_cibles,
    ouvrage_prio)


## Recherche des informations liste 2  -------

maj_roe_l2 <- maj_roe %>%
  st_join(tampon_liste2) %>%
  mutate(long_Esp_arrete = str_length(coalesce(Esp_arrete, "0"))) %>% 
  group_by(identifiant_roe) %>% 
  filter(long_Esp_arrete == max(long_Esp_arrete)) %>% 
  select(identifiant_roe, Esp_arrete, -geometry) %>% # on ne garde que les colonnes d'intérêt
  distinct() %>%
  st_drop_geometry()
# dédoublonage


## Mise à jour des informations liste 2 non renseignées -------

bdroe_dr2 <- bdroe_dr2 %>%
  dplyr::full_join(maj_roe_l2, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>%
  mutate(classement_liste_2 = case_when(
    !is.na(classement_liste_2)  ~ classement_liste_2,
    is.na(classement_liste_2) & !is.na(Esp_arrete) ~ 'Oui',
    is.na(classement_liste_2) & is.na(Esp_arrete) ~ 'Non')) %>% 
  mutate(especes_cibles = case_when(
    (!is.na(especes_cibles) & especes_cibles!= "") ~ especes_cibles,
    (is.na(especes_cibles) | especes_cibles == "") ~ Esp_arrete))  

## Mise à jour Liste1 ----

bdroe_dr2 <- bdroe_dr2 %>%
  st_join(tampon_liste1) %>% 
  mutate(classement_liste_1 = case_when(
    !is.na(classement_liste_1) ~ classement_liste_1,
    is.na(classement_liste_1) & !is.na(Code_numer) ~ 'Oui',
    is.na(classement_liste_1) & is.na(Code_numer) ~ 'Non')) %>% 
  dplyr::select(!(c(Code_numer:CE_RESBIO))) %>%
  group_by(identifiant_roe) %>% 
  distinct()

## Ajout du champ ZAP anguille ----

bdroe_dr2 <- bdroe_dr2 %>%
  st_join(zap_anguille) %>% 
  mutate(zap_ang = case_when(
    !is.na(zap_ang) ~ '1',
    is.na(zap_ang) ~ '0')) %>%
  distinct()

## Ajout du champ SAGE ----

bdroe_dr2 <- bdroe_dr2 %>%
  st_join(sage, 
          largest = T) %>% 
  distinct()


# sauvegarde ----
save(bdroe_dr2,
     file = "data/outputs/maj_roe.RData")

## examen des duplicats ---------
identifiants_roe_dupliques <- bdroe_dr2 %>% 
  sf::st_drop_geometry() %>% 
  group_by(identifiant_roe) %>% 
  tally() %>% 
  filter(n > 1) %>% 
  pull(identifiant_roe)

maj_roe_avec_duplicats2 <- bdroe_dr2 %>% 
  filter(identifiant_roe %in%  identifiants_roe_dupliques)

## fin examen des duplicats

# Création des champs de manques ----

non_valides <- 
  filter(bdroe_dr2, (is.na(statut_nom) | statut_nom == "Non validé" | statut_nom == "")) %>% 
  mutate(non_valides = 1) %>% 
  mutate(non_valides = as.numeric(non_valides)) %>%
  select(identifiant_roe, non_valides) %>% 
  sf::st_drop_geometry()

manque_type <- 
  filter(bdroe_dr2, (is.na(type_nom)|type_nom == "")) %>% 
  mutate(manque_type = 1) %>%
  mutate(manque_type = as.numeric(manque_type)) %>%
  select(geometry, identifiant_roe, manque_type) %>% 
  sf::st_drop_geometry()

manque_etat <- 
  filter(bdroe_dr2, (is.na(etat_nom)|etat_nom == "")) %>% 
  mutate(manque_etat = 1) %>%
  select(identifiant_roe, manque_etat) %>% 
  sf::st_drop_geometry()

manque_hc <- 
  filter(bdroe_dr2, (((is.na(hauteur_chute_etiage) | hauteur_chute_etiage == ""| hauteur_chute_etiage < 0)) & 
                       (is.na(hauteur_chute_etiage_classe) | hauteur_chute_etiage_classe == "Indéterminée" | hauteur_chute_etiage_classe == "") &
                       (is.na(ouv_hauteur_chute_1) | ouv_hauteur_chute_1 =="") & 
                       (is.na(ouv_hauteur_chute_2) | ouv_hauteur_chute_2 =="") &
                       (is.na(ouv_hauteur_chute_3) | ouv_hauteur_chute_3 =="") &
                       (is.na(ouv_hauteur_chute_4) | ouv_hauteur_chute_4 =="") &
                       (is.na(ouv_hauteur_chute_5) | ouv_hauteur_chute_5 =="") &
                       (is.na(hauteur_chute_ICE) | hauteur_chute_ICE ==''))) %>% 
  mutate(manque_hc = 1) %>% 
  select(identifiant_roe, manque_hc) %>% 
  sf::st_drop_geometry()

manque_fip <-
  filter(bdroe_dr2, ((is.na(fpi_nom1) | fpi_nom1 == "")) &
           (is.na(fpi_nom2) | fpi_nom2 == "") &
           (is.na(fpi_nom3) | fpi_nom3 == "") &
           (is.na(fpi_nom4) | fpi_nom4 == "") &
           (is.na(fpi_nom5) | fpi_nom5 == "") &
           (is.na(mesure_corrective_devalaison_equipement) | mesure_corrective_devalaison_equipement == "") & 
           (is.na(mesure_corrective_montaison_equipement)) | mesure_corrective_montaison_equipement == "") %>% 
  mutate(manque_fip = 1) %>% 
  mutate(manque_fip = as.numeric(manque_fip)) %>%
  select(identifiant_roe, manque_fip) %>% 
  sf::st_drop_geometry()

manque_atg_l2 <-
  filter(bdroe_dr2, ((is.na(avis_technique_global)|avis_technique_global=="") & classement_liste_2 == "Oui" )) %>% 
  mutate(manque_atg_l2 = 1) %>% 
  mutate(manque_atg_l2 = as.numeric(manque_atg_l2)) %>%
  select(identifiant_roe, manque_atg_l2) %>% 
  sf::st_drop_geometry()

mec_atg_hc <-
  mutate(bdroe_dr2, mec_atg_hc = ifelse(
    (etat_nom == "Détruit entièrement" | ouv_derasement == "TRUE") & 
      (hauteur_chute_etiage == 0 | 
         ouv_hauteur_chute_1 == 0 | 
         ouv_hauteur_chute_2 == 0 | 
         ouv_hauteur_chute_3 == 0 | 
         ouv_hauteur_chute_4 == 0 |  
         ouv_hauteur_chute_5 == 0 | 
         hauteur_chute_ICE == 0) &
      (avis_technique_global == "" |is.na(avis_technique_global)),
    '1', '0')) %>%
  mutate(mec_atg_hc = as.numeric(mec_atg_hc)) %>%
  select(identifiant_roe, mec_atg_hc) %>% 
  distinct() %>%
  sf::st_drop_geometry()


# Rapatriement des données sur la bdroe ----

bdroe_dr2 <- bdroe_dr2 %>% 
  dplyr::left_join(non_valides) %>% 
  dplyr::left_join(manque_etat) %>% 
  dplyr::left_join(manque_type) %>% 
  dplyr::left_join(manque_hc) %>% 
  dplyr::left_join(manque_fip) %>% 
  dplyr::left_join(manque_atg_l2) %>% 
  dplyr::left_join(mec_atg_hc) %>% 
  mutate(non_valides = recoder_manquantes_en_zero(non_valides),
         manque_etat = recoder_manquantes_en_zero(manque_etat),
         manque_type = recoder_manquantes_en_zero(manque_type),
         manque_hc = recoder_manquantes_en_zero(manque_hc),
         manque_fip = recoder_manquantes_en_zero(manque_fip),
         manque_atg_l2 = recoder_manquantes_en_zero(manque_atg_l2),
         mec_atg_hc = recoder_manquantes_en_zero(mec_atg_hc))

# Création du champ manque_l2 ----

bdroe_dr2 <- bdroe_dr2 %>% 
  mutate(manque_l2 = ifelse(
    (classement_liste_2 == "Oui" & 
       (manque_etat == "1" | 
          manque_type == "1" | 
          manque_hc == "1" | 
          non_valides == "1" | 
          manque_fip == "1")), 
    '1', '0')) %>%
  mutate(manque_l2 = as.numeric(manque_l2)) %>%
  mutate(manque_l2 = case_when(
    is.na(manque_l2) ~ 0, 
    !is.na(manque_l2) ~ manque_l2
  ))


# Mise à jour manque_op ----

bdroe_dr2 <- bdroe_dr2 %>% 
  mutate(manque_op = ifelse(
    (ouvrage_prio == "Oui" & 
       (manque_etat == "1" | 
          manque_type == "1" | 
          manque_hc == "1" | 
          non_valides == "1" | 
          manque_fip == "1")), 
    '1', '0')) %>%
  mutate(manque_op = as.numeric(manque_op)) 

# Mise en évidence dérasement soldés ----

bdroe_dr2 <- bdroe_dr2 %>% 
  mutate(derasement_solde = ifelse(
    ((etat_nom == "Détruit entièrement" | ouv_derasement == "TRUE") & 
       (hauteur_chute_etiage == 0 | 
          ouv_hauteur_chute_1 == 0 | 
          ouv_hauteur_chute_2 == 0 | 
          ouv_hauteur_chute_3 == 0 | 
          ouv_hauteur_chute_4 == 0 |  
          ouv_hauteur_chute_5 == 0 | 
          hauteur_chute_ICE == 0) &
       avis_technique_global == 'Positif'), '1', '0')) %>%
  mutate(derasement_solde  = as.numeric(derasement_solde)) %>%
  mutate(derasement_solde = case_when(
    is.na(derasement_solde) ~ 0,
    !is.na(derasement_solde) ~ derasement_solde
  ))

# Création d'une couche de synthèse des manque de complétude par bassin versant de masse d'eau ----

analyse_manque_me <- bdroe_dr2 %>%
  st_join(masse_eau) %>% 
  sf::st_drop_geometry() %>% 
  filter(statut_nom != 'Gelé' & derasement_solde != '1' & !is.na(cdbvspemdo)) %>%
  select(identifiant_roe, cdbvspemdo, manque_op, manque_l2, manque_etat, manque_type, manque_hc, manque_fip, non_valides) %>%
  group_by (cdbvspemdo) %>%
  summarise(
    ntot_manque_op = sum(manque_op, na.rm = T),
    ntot_manque_l2 = sum(manque_l2, na.rm = T),
    ntot_manque_etat = sum(manque_etat, na.rm = T),
    ntot_manque_type = sum(manque_type, na.rm = T),
    ntot_manque_hc = sum(manque_hc, na.rm = T),
    ntot_manque_fip = sum(manque_fip, na.rm = T),
    ntot_non_valide = sum(non_valides, na.rm = T),)

me_manques_bdroe <- masse_eau %>%
  dplyr::left_join(analyse_manque_me ,
                   by = c("cdbvspemdo" = "cdbvspemdo")) %>%
  select(cdbvspemdo, 
         ntot_manque_op, 
         ntot_manque_l2, 
         ntot_manque_etat, 
         ntot_manque_type, 
         ntot_manque_hc, 
         ntot_manque_fip, 
         ntot_non_valide)


# Calcul des variables par département  ----

dept_analyse_manques <- bdroe_dr2 %>%
  sf::st_drop_geometry() %>% 
  filter(statut_nom != 'Gelé' & derasement_solde != '1') %>%
  select(dept_nom, manque_op, manque_l2, manque_etat, manque_type, manque_hc, manque_fip, non_valides, manque_atg_l2, mec_atg_hc) %>%
  as.data.frame() %>%
  group_by(dept_nom) %>%
  summarise(ntot_ouvrage_analyses = n(),
            ntot_manque_op = sum(manque_op, na.rm = T),
            ntot_manque_l2 = sum(manque_l2, na.rm = T), 
            ntot_manque_etat = sum(manque_etat, na.rm = T), 
            ntot_manque_type = sum(manque_type, na.rm = T), 
            ntot_manque_hc = sum(manque_hc, na.rm = T), 
            ntot_manque_fip = sum(manque_fip, na.rm = T),
            ntot_non_valide = sum(non_valides, na.rm = T), 
            ntot_manque_atg_l2 = sum(manque_atg_l2, na.rm = T),
            ntot_mec_atg_hc = sum(mec_atg_hc, na.rm = T))

openxlsx::write.xlsx(dept_analyse_manques,
                     file = "data/outputs/dept_analyse_manques_20230402.xlsx")


# Export des données

sf::write_sf(obj = bdroe_dr2, dsn = "data/outputs/BDROE_interne_BZH_PDL_20230402.gpkg")

sf::write_sf(obj = me_manques_bdroe, dsn = "data/outputs/me_manques_BDROE_BZH_PDL_20230402.gpkg")

# Valorisation régionale de la "BDROE"

## Etat

bdroe_dr2 %>% 
  mutate(etat_nom = ifelse((etat_nom == "" | is.na(etat_nom)),
                           "Indéterminé",
                           etat_nom)) %>%
  ggplot(aes(x = fct_rev(fct_infreq(etat_nom)))) +
  geom_bar(fill = "blue") +
  coord_flip() +
  labs(x = "Statut de l'ouvrage",
       y = "Nombre d'ouvrages",
       title = "Etat")

## Type
bdroe_dr2 %>% 
  mutate(type_nom = ifelse(type_nom == "",
                           "Indéterminé",
                           type_nom)) %>%
  ggplot(aes(x = fct_rev(fct_infreq(type_nom)))) +
  geom_bar(fill = "blue") +
  coord_flip() +
  labs(x = "Type d'ouvrage",
       y = "Nombre d'ouvrages",
       title = "Type d'ouvrage")

## Hauteur de chute
bdroe_dr2 %>% 
  mutate(hauteur_chute_etiage_classe = ifelse(hauteur_chute_etiage_classe == "",
                                              "Indéterminée",
                                              hauteur_chute_etiage_classe),
         hauteur_chute_etiage_classe = as.factor(hauteur_chute_etiage_classe),
         hauteur_chute_etiage_classe = fct_relevel(hauteur_chute_etiage_classe,
                                                  "Indéterminée",
                                                  "Inférieure à 0.5m",
                                                  "De 0.5m à inférieure à 1m",
                                                  "De 1m à inférieure à 1.5m")) %>% 
  ggplot(aes(y = hauteur_chute_etiage_classe)) +
  geom_bar(fill = "blue") +
  labs(y = "Hauteur de chute",
       x = "Nombre d'ouvrages",
       title = "Hauteur de chute")

## FPI

bdroe_dr2 %>% 
  mutate(fpi_nom1 = ifelse(fpi_nom1 == "",
                           "Indéterminé",
                           fpi_nom1)) %>%
  ggplot(aes(x = fct_rev(fct_infreq(fpi_nom1)))) +
  geom_bar(fill = "blue") +
  coord_flip() +
  labs(x = "Type de franchissement piscicole",
       y = "Nombre d'ouvrages",
       title = "Type de franchissement piscicole")

## ATG

bdroe_dr2 %>% 
  mutate(avis_technique_global = ifelse((avis_technique_global == "" | is.na(avis_technique_global)),
                           "Indéterminé",
                           avis_technique_global)) %>%
  ggplot(aes(x = fct_rev(fct_infreq(avis_technique_global)))) +
  geom_bar(fill = "blue") +
  coord_flip() +
  labs(x = "ATG",
       y = "Nombre d'ouvrages",
       title = "Avis Technique Global")

## Usages

bdroe_dr2 %>% 
  mutate(usage_nom1 = ifelse(usage_nom1 == "",
                           "Indéterminé",
                           usage_nom1)) %>%
  ggplot(aes(x = fct_rev(fct_infreq(usage_nom1)))) +
  geom_bar(fill = "blue") +
  coord_flip() +
  labs(x = "Type d'usage",
       y = "Nombre d'ouvrages",
       title = "Type d'usage")

## Dynamique de création d'ouvrage

ggplot(data = bdroe_dr2, 
       aes(x = lubridate::ymd_hms(date_creation))) +
  geom_histogram(fill = "blue") +
  labs(x = "Date de l'observation",
       y = "Nombre d'ouvrages",
       title = "Dynamique de renseignement : date de création")

## Dynamique de modification d'ouvrage

ggplot(data = bdroe_dr2, 
       aes(x = lubridate::ymd_hms(date_modification_ouvrage))) +
  geom_histogram(fill = "blue") +
  labs(x = "Date de l'observation",
       y = "Nombre d'ouvrages",
       title = "Dynamique de renseignement : date de modification")   

## Dynamique de validation d'ouvrage

ggplot(data = bdroe_dr2, 
       aes(x = lubridate::ymd_hms(date_validation_ouvrage))) +
  geom_histogram(fill = "blue") +
  labs(x = "Date de l'observation",
       y = "Nombre d'ouvrages",
       title = "Dynamique de renseignement : date de validation")   

## Dynamique hauteur de chute d'ouvrage

ggplot(data = bdroe_dr2, 
       aes(x = lubridate::ymd(ouv_date_hauteur_chute_1))) +
  geom_histogram(fill = "blue") +
  labs(x = "Date de l'observation",
       y = "Nombre d'ouvrages",
       title = "Dynamique de renseignement : hauteur de chute 1")   

ggplot(data = bdroe_dr2, 
       aes(x = lubridate::ymd(ouv_date_hauteur_chute_2))) +
  geom_histogram(fill = "blue") +
  labs(x = "Date de l'observation",
       y = "Nombre d'ouvrages",
       title = "Dynamique de renseignement : hauteur de chute 2")   

