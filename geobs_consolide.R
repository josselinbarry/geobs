
## VERSION FINALISEE AU 202501

## En cours d'ajout sur la partie analytique

# Library ----

library(tidyverse)
#library(lubridate)
#library(RcppRoll)
#library(DT)
#library(readxl)
library(dbplyr)
#library(RPostgreSQL)
#library(rsdmx)
library(sf)
#library(stringi)
#library(plyr)
devtools::install_github("PascalIrz/aspe")
aspe::misc_nom_dernier_fichier
  
library(lubridate)
library(RcppRoll)
library(DT)
library(readxl)
library(dbplyr)
library(RPostgreSQL)
library(rsdmx)
library(sf)
library(stringi)
library(plyr)


# Chargement données obstacles ----

## BDOE ----

bdoe <- data.table::fread(file = "data/export_de_base_20250106.csv",
                          encoding = "UTF-8")

sans_fiche_bdoe_bzh <- data.table::fread(file = "data/bdoe/bzh_export_de_base_sansFiches_20250106.csv",
                                     encoding = "Latin-1")

sans_fiche_bdoe_pdl <- data.table::fread(file = "data/bdoe/pdl_export_de_base_sansFiches_20250106.csv",
                                         encoding = "Latin-1")

sans_fiche_bdoe_sn <- data.table::fread(file = "data/bdoe/sn_export_de_base_sansFiches_20250107.csv",
                                         encoding = "Latin-1")

roe_sans_fiche_bdoe <- dplyr::bind_rows(sans_fiche_bdoe_bzh, sans_fiche_bdoe_pdl, sans_fiche_bdoe_sn) %>%
  mutate(sans_fiche_bdoe = 1)

## ROE par bassin ----

roe_lb <- data.table::fread(file = "data/lb_temp20241201.csv",
                            encoding = "Latin-1",
                            colClasses = c("date_creation" = "character"))

roe_sn <- data.table::fread(file = "data/sn_temp20241201.csv",
                            encoding = "Latin-1",
                            colClasses = c("date_creation" = "character"))

roe_nr <- data.table::fread(file = "data/nr_temp20241201.csv",
                            encoding = "Latin-1",
                            colClasses = c("date_creation" = "character"))

## Fusionner les ROE par bassin ---- 

roe_lb_sn_nr <- dplyr::bind_rows(roe_lb, roe_sn, roe_nr)

## Basculer le ROE en sf_geom ----

roe_geom <- roe_lb_sn_nr %>% 
  filter(!is.na(x_l93)) %>%
  st_as_sf(coords = c("x_l93", "y_l93"), remove = FALSE, crs = 2154) 

## Attribuer les dept_code non renseignés ----

dprt <- 
  sf::read_sf(dsn = "data/DEPARTEMENT.shp")

cd_dprt_manquant_roe <- roe_geom %>%
  select(identifiant_roe, dept_code, x_l93, y_l93) %>%
  filter((dept_code == '' | is.na(dept_code))) %>%
  filter (x_l93 > 85000 & x_l93 < 560000 & y_l93 > 6570000 & y_l93 < 6900000 )

plus_proche_dprt <- sf::st_nearest_feature(x = cd_dprt_manquant_roe,
                                             y = dprt)

dist_dprt <- st_distance(cd_dprt_manquant_roe, dprt[plus_proche_dprt,], by_element = TRUE)

view(plus_proche_dprt)

cd_dprt_roe <- cd_dprt_manquant_roe %>% 
  cbind(dist_dprt) %>% 
  cbind(dprt[plus_proche_dprt,]) %>% 
  select(identifiant_roe,
         dprt_le_plus_proche = INSEE_DEP,
         distance_dprt = dist_dprt) %>% 
  sf::st_drop_geometry() %>% 
  mutate(distance_dprt_km = round(distance_dprt/1000,3))

## Mise à jour du dprt_code de la couche roe_geom

roe_geom_cd <- roe_geom  %>%
  left_join(cd_dprt_roe, by = c("identifiant_roe" = "identifiant_roe")) %>%  
  mutate(dept_code = ifelse(
    (dept_code == '' | is.na(dept_code)),
    dprt_le_plus_proche,
    dept_code)) %>%
  distinct() 

roe_geom <- roe_geom_cd %>%
  select(-dprt_le_plus_proche, -distance_dprt, -distance_dprt_km)

## Mise à jour des noms de département ----

roe_geom_nom <- roe_geom  %>%
  left_join(dprt %>%
              st_drop_geometry(), 
            by = c("dept_code" = "INSEE_DEP")) %>%  
  mutate(dept_nom == nom_dept) %>%
  distinct() 

roe_geom <- roe_geom_nom %>%
  select(-nom_dept)

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

bv_me <- 
  sf::read_sf(dsn = "data/bassins_versants_me_zone_etude.gpkg") %>%
  st_transform(crs = 2154)

# Mise à jour du code masse d'eau ----

cd_me_manquant_roe <- bdroe_dr2 %>%
  select(identifiant_roe, masse_eau_code) %>%
  filter((masse_eau_code == '' | is.na(masse_eau_code))) 

plus_proche_me <- sf::st_nearest_feature(x = cd_me_manquant_roe,
                                         y = bv_me)

dist_me <- st_distance(cd_me_manquant_roe, bv_me[plus_proche_me,], by_element = TRUE)

view(plus_proche_me)

cd_me_roe <- cd_me_manquant_roe %>% 
  cbind(dist_me) %>% 
  cbind(bv_me[plus_proche_me,]) %>% 
  select(identifiant_roe,
         me_le_plus_proche = cdeumassed,
         distance_me = dist_me) %>% 
  sf::st_drop_geometry() %>% 
  mutate(distance_me_km = round(distance_me/1000,3))

## Mise à jour du me_code de la couche roe_geom

roe_geom_cd_me <- bdroe_dr2  %>%
  left_join(cd_me_roe, by = c("identifiant_roe" = "identifiant_roe")) %>%  
  mutate(masse_eau_code = ifelse(
    (masse_eau_code == '' | is.na(masse_eau_code)),
    me_le_plus_proche,
    masse_eau_code)) %>%
  distinct() 

bdroe_dr2 <- roe_geom_cd_me %>%
  select(-me_le_plus_proche, -distance_me, -distance_me_km)

# Mise à jour Ouvrages prioritaires ----
# Obsolète 

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
    especes_cibles)


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

bdroe_dr2 <- bdroe_dr2 %>%
  select(-Esp_arrete)

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

## Distinction des ouvrages sans fiche BDOE ----

bdroe_dr2 <- bdroe_dr2 %>%
  left_join(y = roe_sans_fiche_bdoe, join_by("identifiant_roe" == "cdobstecou")) %>% 
  mutate(sans_fiche_bdoe = ifelse(
    is.na(sans_fiche_bdoe), 
    '0', sans_fiche_bdoe))

# sauvegarde ----

save(bdroe_dr2,
     file = "data/outputs/maj_roe.RData")

load(file = "data/outputs/maj_roe.RData")

write.csv(roe_sans_fiche_bdoe, file = "data/outputs/sans_fiche_bdoe_20250106.csv")

bdroe_test <- roe_lb_sn_nr %>%
  filter("identifiant_roe" == 'ROE127262')

# MAJ OP vraie mais attendre demarche priorisation PDL = PLAGEPOMI ----

#ouvrages_prioritaires <- 
  filter(bdroe_dr2, demarche_priorisation_4 == 'PLAGEPOMI') %>% 
  mutate(ouvrage_prioritaire = 1) %>% 
  mutate(ouvrage_prioritaire = as.numeric(ouvrage_prioritaire)) %>%
  select(identifiant_roe, ouvrage_prioritaire) %>% 
  sf::st_drop_geometry()

# Mise à jour OP dans l'attente des PDL ----

bdroe_dr2 <- bdroe_dr2 %>% 
  left_join(ouvrages_prioritaires %>%
              select(-nom_principal, -nom_secondaire)) %>%
  mutate(ouvrage_prioritaire = ifelse(
    ((ouvrage_prio == "oui" & 
      dept_code %in% c('44','49','53','72','85')) |
      (demarche_priorisation_4 == 'PLAGEPOMI' & 
         dept_code %in% c('22','29','35','56'))), 
    '1', '0')) %>%
  mutate(ouvrage_prioritaire = ifelse(
    is.na(ouvrage_prioritaire), 
    '0', ouvrage_prioritaire)) %>%
  mutate(ouvrage_prioritaire = as.numeric(ouvrage_prioritaire)) %>%
  select(-ouvrage_prio)

## examen des duplicats ----

identifiants_roe_dupliques <- bdroe_dr2_maj %>% 
  sf::st_drop_geometry() %>% 
  group_by(identifiant_roe) %>% 
  tally() %>% 
  filter(n > 1) %>% 
  pull(identifiant_roe)

# Correction "manuelle" duplicatats ----

bdroe_dr2 <- bdroe_dr2 %>%
  filter(coalesce(hauteur_chute_ICE,1000) != '59')

maj_roe_avec_duplicats2 <- bdroe_dr2_2 %>% 
  filter(identifiant_roe %in%  identifiants_roe_dupliques)

## fin examen des duplicats


# Filtres ----

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

manque_fip <- bdroe_dr2 %>%
  filter((is.na(fpi_nom1) | fpi_nom1 == "") &
           (is.na(fpi_nom2) | fpi_nom2 == "") &
           (is.na(fpi_nom3) | fpi_nom3 == "") &
           (is.na(fpi_nom4) | fpi_nom4 == "") &
           (is.na(fpi_nom5) | fpi_nom5 == "") & 
  (is.na(mesure_corrective_devalaison_equipement) | mesure_corrective_devalaison_equipement == "" | mesure_corrective_devalaison_equipement == "Non") & 
  (is.na(mesure_corrective_montaison_equipement) | mesure_corrective_montaison_equipement == ""  | mesure_corrective_montaison_equipement == "Non"))  %>% 
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

bdroe_dr2_maj <- bdroe_dr2 %>% 
  dplyr::left_join(non_valides, 
                   by = c("identifiant_roe" = "identifiant_roe"))%>% 
  mutate(non_valides = case_when(
    non_valides == "1" ~ '1',
    non_valides == "" ~ '0',
    is.na(non_valides) ~ '0'))%>%
  mutate(non_valides = as.numeric(non_valides)) %>%
  dplyr::left_join(manque_etat, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  mutate(manque_etat = case_when(
    manque_etat == "1" ~ '1',
    manque_etat == "" ~ '0',
    is.na(manque_etat) ~ '0'))%>%
  mutate(manque_etat = as.numeric(manque_etat)) %>%
  dplyr::left_join(manque_type, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  mutate(manque_type = case_when(
    manque_type == "1" ~ '1',
    manque_type == "" ~ '0',
    is.na(manque_type) ~ '0'))%>%
  mutate(manque_type = as.numeric(manque_type)) %>%
  dplyr::left_join(manque_hc, 
                   by = c("identifiant_roe" = "identifiant_roe"))%>% 
  mutate(manque_hc = case_when(
    manque_hc == "1" ~ '1',
    manque_hc == "" ~ '0',
    is.na(manque_hc) ~ '0'))%>%
  mutate(manque_hc = as.numeric(manque_hc)) %>%
  dplyr::left_join(manque_fip, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  mutate(manque_fip = case_when(
    manque_fip == "1" ~ '1',
    manque_fip == "" ~ '0',
    is.na(manque_fip) ~ '0'))%>%
  mutate(manque_fip = as.numeric(manque_fip)) %>%
  dplyr::left_join(manque_atg_l2, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  mutate(manque_atg_l2 = case_when(
    manque_atg_l2 == "1" ~ '1',
    manque_atg_l2 == "" ~ '0',
    is.na(manque_atg_l2) ~ '0'))%>%
  mutate(manque_atg_l2 = as.numeric(manque_atg_l2)) %>%
  dplyr::left_join(mec_atg_hc, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>%
  mutate(mec_atg_hc = case_when(
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

att_manque_l2 <- bdroe_dr2_maj %>%
  filter(manque_l2 == 1)

# Mise à jour manque_op 

bdroe_dr2_maj <- bdroe_dr2_maj %>% 
  mutate(manque_op = ifelse(
    (ouvrage_prioritaire == "1" & 
       (manque_etat == "1" | 
          manque_type == "1" | 
          manque_hc == "1" | 
          non_valides == "1" | 
          manque_fip == "1")), 
    '1', '0')) %>%
  mutate(manque_op = as.numeric(manque_op)) 

att_manque_op <- bdroe_dr2_maj %>%
  filter(manque_op == 1)

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
  mutate(derasement_solde  = as.numeric(derasement_solde)) %>%
  mutate(derasement_solde = case_when(
    is.na(derasement_solde) ~ 0,
    !is.na(derasement_solde) ~ derasement_solde
  ))

# Nettoyage des champs inutiles ----

bdroe_dr2_maj <- bdroe_dr2_maj %>%
  select(-statut_code, 
         -etat_code, 
         -type_code, 
         -stype_code, 
         -x_rraf91, 
         -y_rraf91, 
         -x_rgfg95, 
         -y_rgfg95, 
         -x_rgm04, 
         -y_rgm04, 
         -x_rgr92, 
         -y_rgr92, 
         -position_wgs84, 
         -XCartL93, 
         -YCartL93, 
         -XTopoL93, 
         -YTopoL93, 
         -XCartrgfg95, 
         -YCartrgfg95, 
         -XToporgfg95, 
         -YToporgfg95, 
         -XCartrgm04, 
         -YCartrgm04, 
         -XToporgm04, 
         -YToporgm04, 
         -XCartrgr92, 
         -YCartrgr92, 
         -XToporgr92, 
         -YToporgr92, 
         -XCartrraf91, 
         -YCartrraf91, 
         -XToporraf91, 
         -YToporraf91, 
         -CodeProjSandre, 
         -fpi_code1,
         -fpi_code2,
         -fpi_code3,
         -fpi_code4,
         -fpi_code5,
         -emo_code1,
         -emo_code2,
         -emo_code3,
         -fnt_code1,
         -fnt_code2,
         -fnt_code3,
         -fnt_nom3,
         -usage_code1,
         -usage_code2,
         -usage_code3,
         -usage_code4,
         -ouvrage_fils4, 
         -ouvrage_fils5, 
         -ouvrage_fils6, 
         -ouvrage_fils7,
         -ouvrage_fils8, 
         -altitude.x,
         -pk_carthage,
         -position_bd_topo,
         -position_bd_carthage,
         -nomprincip,
         -ouv_coord_x,
         -ouv_coord_y,
         -ouv_type_nom,
         -ouv_usages,
         -ouv_etat,
         -ouv_liaison,
         -ouv_ouvrage_lie, 
         -commune, 
         -departement,
         -statut_roe)

# Calculs variables de Rmarkdown ----

bdroe_dr2_maj <- bdroe

bdroe_dr2_valid <- bdroe_dr2_maj %>%
  filter(statut_nom != "Gelé" & derasement_solde == 0)

nb_non_valides <- 
  filter(bdroe_dr2_valid %>%
           filter((is.na(statut_nom) | statut_nom == "Non validé" | statut_nom == ""))) %>%
  select(identifiant_roe, dept_code, non_valides) %>% 
  sf::st_drop_geometry()

nb_manque_type <- 
  filter(bdroe_dr2_valid, (is.na(type_nom)|type_nom == "")) %>% 
  select(identifiant_roe, dept_code, manque_type) %>% 
  sf::st_drop_geometry()

nb_manque_etat <- 
  filter(bdroe_dr2_valid, (is.na(etat_nom)|etat_nom == "")) %>% 
  select(identifiant_roe, dept_code, manque_etat) %>% 
  sf::st_drop_geometry()

nb_manque_hc <- 
  filter(bdroe_dr2_valid, (((is.na(hauteur_chute_etiage) | hauteur_chute_etiage == ""| hauteur_chute_etiage < 0)) & 
                       (is.na(hauteur_chute_etiage_classe) | hauteur_chute_etiage_classe == "Indéterminée" | hauteur_chute_etiage_classe == "") &
                       (is.na(ouv_hauteur_chute_1) | ouv_hauteur_chute_1 =="") & 
                       (is.na(ouv_hauteur_chute_2) | ouv_hauteur_chute_2 =="") &
                       (is.na(ouv_hauteur_chute_3) | ouv_hauteur_chute_3 =="") &
                       (is.na(ouv_hauteur_chute_4) | ouv_hauteur_chute_4 =="") &
                       (is.na(ouv_hauteur_chute_5) | ouv_hauteur_chute_5 =="") &
                       (is.na(hauteur_chute_ICE) | hauteur_chute_ICE ==''))) %>% 
  select(identifiant_roe, dept_code, manque_hc) %>% 
  sf::st_drop_geometry()

nb_manque_fip <- bdroe_dr2_valid %>%
  filter((is.na(fpi_nom1) | fpi_nom1 == "") &
           (is.na(fpi_nom2) | fpi_nom2 == "") &
           (is.na(fpi_nom3) | fpi_nom3 == "") &
           (is.na(fpi_nom4) | fpi_nom4 == "") &
           (is.na(fpi_nom5) | fpi_nom5 == "") & 
           (is.na(mesure_corrective_devalaison_equipement) | mesure_corrective_devalaison_equipement == "" | mesure_corrective_devalaison_equipement == "Non") & 
           (is.na(mesure_corrective_montaison_equipement) | mesure_corrective_montaison_equipement == ""  | mesure_corrective_montaison_equipement == "Non"))  %>% 
  select(identifiant_roe, dept_code, manque_fip) %>% 
  sf::st_drop_geometry()

nb_manque_atg_l2 <-
  filter(bdroe_dr2_valid, ((is.na(avis_technique_global)|avis_technique_global=="") & classement_liste_2 == "Oui" )) %>% 
  select(identifiant_roe, dept_code, manque_atg_l2) %>% 
  sf::st_drop_geometry()

nb_mec_atg_hc <- bdroe_dr2_valid %>%
  filter((etat_nom == "Détruit entièrement" | ouv_derasement == "TRUE") & 
           (hauteur_chute_etiage == 0 |
           ouv_hauteur_chute_1 == 0 | 
           ouv_hauteur_chute_2 == 0 | 
           ouv_hauteur_chute_3 == 0 | 
           ouv_hauteur_chute_4 == 0 |  
           ouv_hauteur_chute_5 == 0 | 
           hauteur_chute_ICE == 0) &
      (avis_technique_global == "" |is.na(avis_technique_global))) %>%
  select(identifiant_roe, dept_code, mec_atg_hc) %>% 
  distinct() %>%
  sf::st_drop_geometry()

nb_manque_op <- bdroe_dr2_valid %>%
  filter(manque_op ==1)

nb_manque_l2 <- bdroe_dr2_valid %>%
  filter(manque_l2 ==1)

nb_ouvrages_prioritaires <- bdroe_dr2_valid %>%
  filter(ouvrage_prioritaire == 1)

nb_ouvrages_l2 <- bdroe_dr2_valid %>%
  filter(classement_liste_2 == 'Oui')

nb_atg_l2 <- bdroe_dr2_valid %>%
  filter((is.na(avis_technique_global) | avis_technique_global == '') & classement_liste_2 == 'Oui')

# Sauvegarder la couche bdroe_dr2_maj ----

sf::write_sf(obj = bdroe_dr2_maj, dsn = "data/outputs/BDROE_interne_BZH_PDL_20241201.gpkg")

save(bdroe,
     bdroe_dr2_valid,
     nb_non_valides,
     nb_manque_etat,
     nb_manque_type,
     nb_manque_hc,
     nb_manque_fip,
     nb_manque_atg_l2,
     nb_manque_op,
     nb_manque_l2,
     nb_ouvrages_prioritaires,
     nb_ouvrages_l2,
     nb_atg_l2,
     nb_mec_atg_hc,
     file = "data/outputs/bdroe.RData")
