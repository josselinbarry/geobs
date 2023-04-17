
# Library ----

library(tidyverse)
library(lubridate)
library(RcppRoll)
library(DT)
library(readxl)
library(dbplyr)
library(RPostgreSQL)
library(rsdmx)
library(sf)
library(stringi)

# Chargement données obstacles ----

## BDOE ----

bdoe_bzh <- data.table::fread(file = "data/export_de_base_20230330.csv")

bdoe_pdl <- data.table::fread(file = "data/export_de_base_20230330.csv")

## ROE ----

roe_lb <- readr::read_csv(file = "data/lb_temp20221219.csv",
                          locale(encoding = "UTF-8"),)

roe_sn <- readr::read_csv2(file = "data/sn_temp20221219.csv",
                           locale(encoding = "UTF-8"),)

# Fusionner les tables ---- 

roe_lb_sn <- dplyr::bind_rows(roe_lb, roe_sn)

bdoe_dr2 <- dplyr::bind_rows(bdoe_bzh, bdoe_pdl)

# Basculer le ROE en sf_geom

roe_geom <- roe_lb_sn %>% 
  st_as_sf(coords = c("x_l93", "y_l93"), remove = FALSE, crs = 2154) 
  
# Jointure et sélection des ROE et BDOE ----

bdroe <- roe_geom %>% 
  dplyr::full_join(bdoe_bzh, 
                   by = c("identifiant_roe" = "cdobstecou")) %>% 
  dplyr::filter(departement %in% c('22', '29', '35', '56', '44', '49', '53', '72', '85'))

# Import des données de contexte

tampon_liste2 <- 
  sf::read_sf(dsn = "data/Liste2_LB_2018_holobiotiques.gpkg") %>% 
  sf::st_buffer(liste2, dist = 100)

tampon_liste1 <- 
  sf::read_sf(dsn = "data/Liste1_214.17.gpkg") %>% 
  sf::st_buffer(liste1, dist = 100)

zap_pdl <- 
  sf::read_sf(dsn = "data/Zone_Prioritaire_Anguille_PDL.gpkg")

zap_bzh <- 
  sf::read_sf(dsn = "data/zap_anguille_bzh.gpkg")

sage <- 
  sf::read_sf(dsn = "data/Sage.gpkg")

departement <- 
  sf::read_sf(dsn = "data/xxx.gpkg")

# Mise à jour spatiale ----

maj_roe <- bdroe %>% 
  dplyr::select(identifiant_roe, statut_nom, etat_nom, type_nom, fpi_nom1, fpi_nom2, fpi_nom3, fpi_nom4, fpi_nom5, hauteur_chute_etiage, hauteur_chute_etiage_classe, ouv_hauteur_chute_1, ouv_hauteur_chute_2, ouv_hauteur_chute_3, ouv_hauteur_chute_4, ouv_hauteur_chute_5, hauteur_chute_ICE, ouv_arasement, ouv_derasement, mesure_corrective_devalaison_equipement, mesure_corrective_montaison_equipement, avis_technique_global, classement_liste_1, classement_liste_2, especes_cibles)


## Mise à jour département


## Mise à jour ZAP

st_crs(bdroe) == st_crs(zap_bzh)
st_crs(bdroe) == st_crs(zap_pdl)

st_geometry(roe_geom)
st_geometry(tampon_liste1)
st_geometry(tampon_liste2)

## Mise à jour SAGE ----

st_crs(bdroe) == st_crs(sage)

jointure_l1 <- 
  st_join(bdroe_bzh_pdl, sage, join = st_intersects)


## Mise à jour Liste1 ----

# st_crs(bdroe) == st_crs(tampon_liste1)
# 
# st_geometry(tampon_liste1) <- "geometry"
 

# 
# maj_roe_l1 <- st_intersection(st_union(maj_roe), st_union(tampon_liste1))
# 
#   mutate(liste1 = case_when(Code_numer == NA ~'Non',
#                                        TRUE ~ 'Oui')) %>% 
#   mutate(classement_liste_1 = case_when(classement_liste_1 == NA ~ liste1,
#                                        TRUE ~ classement_liste_1))

## Mise à jour Liste2 et espèces cibles ----
  
st_crs(bdroe) == st_crs(tampon_liste2)
  

#Filtres

non_valides <- 
  filter(maj_roe, is.na(statut_nom) | statut_nom == "Non validé") %>% 
  mutate(non_valides = "Oui") %>% 
  select(identifiant_roe, non_valides) %>% 
  sf::st_drop_geometry()

manque_type <- 
  filter(maj_roe, is.na(type_nom)) %>% 
  mutate(manque_type = "Oui") %>% 
  select(identifiant_roe, manque_type) %>% 
  sf::st_drop_geometry()

manque_etat <- 
  filter(maj_roe, is.na(etat_nom)) %>% 
  mutate(manque_etat = "Oui") %>% 
  select(identifiant_roe, manque_etat) %>% 
  sf::st_drop_geometry()

manque_hc <- 
  filter(maj_roe, (is.na(hauteur_chute_etiage) | hauteur_chute_etiage < 0) & 
           (is.na(hauteur_chute_etiage_classe) | hauteur_chute_etiage_classe == "Indéterminée") &
           is.na(ouv_hauteur_chute_1) & 
           is.na(ouv_hauteur_chute_2) &
           is.na(ouv_hauteur_chute_3) &
           is.na(ouv_hauteur_chute_4) &
           is.na(ouv_hauteur_chute_5) &
           is.na(hauteur_chute_ICE)) %>% 
  mutate(manque_hc = "Oui") %>% 
  select(identifiant_roe, manque_hc) %>% 
  sf::st_drop_geometry()
  
manque_fip <-
  filter(maj_roe, is.na(dispo_franch_piscicole_1) &
           is.na(dispo_franch_piscicole_1) &
           is.na(dispo_franch_piscicole_2) &
           is.na(dispo_franch_piscicole_3) &
           is.na(dispo_franch_piscicole_4) &
           is.na(dispo_franch_piscicole_5) &
           is.na(mesure_corrective_devalaison_equipement) & 
           is.na(mesure_corrective_montaison_equipement)) %>% 
  mutate(manque_fip = "Oui") %>% 
  select(identifiant_roe, manque_fip) %>% 
  sf::st_drop_geometry()

manque_atg_l2 <-
  filter(maj_roe, is.na(avis_technique_global) & bdoe_classement_liste_2 == "Oui" ) %>% 
  mutate(manque_atg_l2 = "Oui") %>% 
  select(identifiant_roe, manque_atg_l2) %>% 
  sf::st_drop_geometry()

mec_atg_hc <-
  filter(maj_roe, (hauteur_chute_etiage == 0 | 
                     ouv_hauteur_chute_1 == 0 | 
                     ouv_hauteur_chute_2 == 0 | 
                     ouv_hauteur_chute_3 == 0 | 
                     ouv_hauteur_chute_4 == 0 |  
                     ouv_hauteur_chute_5 == 0 | 
                     hauteur_chute_ICE == 0)) %>% 
  mutate(mec_atg_hc = "Oui") %>% 
  select(identifiant_roe, mec_atg_hc) %>% 
  sf::st_drop_geometry()

# Rapatriement des données sur la bdroe

bdroe_maj <- bdroe %>% 
  dplyr::full_join(non_valides, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  dplyr::full_join(manque_etat, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  dplyr::full_join(manque_type, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  dplyr::full_join(manque_hc, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  dplyr::full_join(manque_fip, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  dplyr::full_join(manque_atg_l2, 
                   by = c("identifiant_roe" = "identifiant_roe")) %>% 
  dplyr::full_join(mec_atg_hc, 
                   by = c("identifiant_roe" = "identifiant_roe")) 
  
bdroe_maj <- bdroe_maj %>% 
  mutate(manque_l2 = ifelse(
    (classement_liste_2 == "Oui" & 
      (manque_etat == 'Oui' | 
       manque_type == 'Oui' | 
       manque_hc == 'Oui' | 
       non_valides == 'Oui')), 
    'Oui', ''))

bdroe_maj <- bdroe_maj %>% 
  mutate(manque_op = ifelse(
    (ouvrage_prioritaire == "Oui" & 
       (manque_etat == 'Oui' | 
          manque_type == 'Oui' | 
          manque_hc == 'Oui' | 
          non_valides == 'Oui')), 
    'Oui', ''))

  
  
                 
  