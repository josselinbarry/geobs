# Library ----

library(tidyverse)
#library(lubridate)
#library(RcppRoll)
#library(DT)
#library(readxl)
#library(dbplyr)
#library(RPostgreSQL)
#library(rsdmx)
library(sf)
#library(stringi)
library(plyr)


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


# Mise à jour Ouvrages prioritaires

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
# BUG

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

# sauvegarde ----
save(bdroe_dr2,
     file = "data/outputs/maj_roe.RData")


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


#Filtres

non_valides <- 
  filter(bdroe_dr2, (is.na(statut_nom) | statut_nom == "Non validé" | statut_nom == "")) %>% 
  mutate(non_valides = 1) %>% 
  mutate(non_valides = as.numeric(non_valides)) %>%
  select(identifiant_roe, non_valides, dept_code) %>% 
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
  mutate(manque_etat = as.numeric(manque_etat)) %>%
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
  mutate(manque_hc = as.numeric(manque_hc)) %>%
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


# Rapatriement des données sur la bdroe

bdroe_dr2_maj <- bdroe_dr2 %>% 
  dplyr::left_join(non_valides, 
                   by = c("identifiant_roe" = "identifiant_roe"))%>% 
  mutate(bdroe_dr2_maj, non_valides = case_when(
    non_valides == "1" ~ '1',
    non_valides == "" ~ '0',
    is.na(non_valides) ~ '0'))%>%
  mutate(non_valides = as.numeric(non_valides)) %>%
  dplyr::left_join(manque_etat, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  mutate(bdroe_dr2_maj, manque_etat = case_when(
    manque_etat == "1" ~ '1',
    manque_etat == "" ~ '0',
    is.na(manque_etat) ~ '0'))%>%
  mutate(manque_etat = as.numeric(manque_etat)) %>%
  dplyr::left_join(manque_type, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  mutate(bdroe_dr2_maj, manque_type = case_when(
    manque_type == "1" ~ '1',
    manque_type == "" ~ '0',
    is.na(manque_type) ~ '0'))%>%
  mutate(manque_type = as.numeric(manque_type)) %>%
  dplyr::left_join(manque_hc, 
                   by = c("identifiant_roe" = "identifiant_roe"))%>% 
  mutate(bdroe_dr2_maj, manque_hc = case_when(
    manque_hc == "1" ~ '1',
    manque_hc == "" ~ '0',
    is.na(manque_hc) ~ '0'))%>%
  mutate(manque_hc = as.numeric(manque_hc)) %>%
  dplyr::left_join(manque_fip, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  mutate(bdroe_dr2_maj, manque_fip = case_when(
    manque_fip == "1" ~ '1',
    manque_fip == "" ~ '0',
    is.na(manque_fip) ~ '0'))%>%
  mutate(manque_fip = as.numeric(manque_fip)) %>%
  dplyr::left_join(manque_atg_l2, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  mutate(bdroe_dr2_maj, manque_atg_l2 = case_when(
    manque_atg_l2 == "1" ~ '1',
    manque_atg_l2 == "" ~ '0',
    is.na(manque_atg_l2) ~ '0'))%>%
  mutate(manque_atg_l2 = as.numeric(manque_atg_l2)) %>%
  dplyr::left_join(mec_atg_hc, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>%
  mutate(bdroe_dr2_maj, mec_atg_hc = case_when(
    mec_atg_hc == "1" ~ '1',
    mec_atg_hc == "" ~ '0',
    is.na(mec_atg_hc) ~ '0')) %>%
  mutate(mec_atg_hc = as.numeric(mec_atg_hc)) %>%
  mutate(mec_atg_hc = case_when(
    is.na(mec_atg_hc) ~ 0,
    !is.na(mec_atg_hc) ~ mec_atg_hc
  ))


# Mise à jour manque_l2

bdroe_dr2_maj <- bdroe_dr2_maj %>% 
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


# Mise à jour manque_op

bdroe_dr2_maj <- bdroe_dr2_maj %>% 
  mutate(manque_op = ifelse(
    (ouvrage_prio == "Oui" & 
       (manque_etat == "1" | 
          manque_type == "1" | 
          manque_hc == "1" | 
          non_valides == "1" | 
          manque_fip == "1")), 
    '1', '0')) %>%
  mutate(manque_op = as.numeric(manque_op)) 

# Mise en évidence dérasement soldés

bdroe_dr2_maj <- bdroe_dr2_maj %>% 
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
  mutate(derasement_solde = as.numeric(derasement_solde)) %>%
  mutate(derasement_solde = case_when(
    is.na(derasement_solde) ~ 0,
    !is.na(derasement_solde) ~ derasement_solde
  ))

# Sauvegarder la couche bdroe_dr2_maj

sf::write_sf(obj = bdroe_dr2_maj, dsn = "data/outputs/BDROE_interne_BZH_PDL_20230402.gpkg")

# Calcul des variables par département

bilan_non_valide <-non_valides %>%
  group_by(dept_code) %>%
  count()

            