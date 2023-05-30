

# tools

 rm(roe_unique)
# 
test_doublons_bdroe <- bdroe %>% 
group_by(identifiant_roe) %>% 
summarise(n_ligne = n()) %>% 
filter(n_ligne>1)


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

# Retravailler les données ---- 

## PB Supprimer les doublons de la BDOE ----

bdoe_unique <- dplyr::distinct(bdoe)

## Fusionner les ROE par bassin ---- 

roe_lb_sn <- dplyr::bind_rows(roe_lb, roe_sn)

## Basculer le ROE en sf_geom ----

roe_geom <- roe_lb_sn %>% 
  st_as_sf(coords = c("x_l93", "y_l93"), remove = FALSE, crs = 2154) 

## Jointure ROE et BDOE ----

bdroe <- roe_geom %>% 
  dplyr::left_join(bdoe, 
                   by = c("identifiant_roe" = "cdobstecou"))

# Import des données de contexte ----

liste2 <- 
  sf::read_sf(dsn = "data/Liste2_LB_2018_holobiotiques.shp")

tampon_liste2 <-
  sf::st_buffer(liste2, dist = 100)

liste1 <- 
  sf::read_sf(dsn = "data/Liste1_214.17.shp")

tampon_liste1 <-
  sf::st_buffer(liste1, dist = 100)

# pb ici
# zap_pdl <- 
#  sf::read_sf(dsn = "data/Zone_Prioritaire_Anguille_PDL.MAP")

# test = st_read('data/Zone_Prioritaire_Anguille_PDL.MAP')



# zap_bzh <- 
#  sf::read_sf(dsn = "data/zap_anguille_bzh.gpkg")

#sage <- 
#  sf::read_sf(dsn = "data/Sage.gpkg")

departements <- 
  sf::read_sf(dsn = "data/DEPARTEMENT.shp")

ouvrages_prioritaires <-
  data.table::fread(file = "data/20200507_Ouv_prioritaires BZH_PDL.csv")

# Mise à jour des codes départementaux NA et filtre des ouvrages BZH et PDL
#Est-ce utile (calcul ? appliqué à BDOE ?) ? le champ semble être complet
## Nearest 

plus_proche_dept <- sf::st_nearest_feature(x = bdroe,
                                           y = departements)

dist <- st_distance(bdroe, departements[plus_proche_dept,], by_element = TRUE)

cd_dprt <- bdroe %>% 
  cbind(dist) %>% 
  cbind(departements[plus_proche_dept,]) %>% 
  select(identifiant_roe,
         dept_le_plus_proche = INSEE_DEP,
         distance_m = dist) %>% 
  sf::st_drop_geometry() %>% 
  mutate(distance_m = round(distance_m))

## Jointure et filtre des ouvrages ?????

bdroe2 <- bdroe %>% 
  dplyr::left_join(cd_dprt, 
                   by = c("identifiant_roe" = "identifiant_roe"))

bdroe3 <- bdroe2 %>% 
  mutate(dept_code = as.character(dept_code)) %>% 
  mutate(dept_le_plus_proche = as.character(dept_le_plus_proche)) %>% 
  mutate(dept_code = case_when(
    !is.na(dept_code) ~ dept_code,
    is.na(dept_code) ~ dept_le_plus_proche)) %>% 
  dplyr::filter(dept_code %in% c('22', '29', '35', '56', '44', '49', '53', '72', '85')) %>% 
  dplyr::select(!(c(dept_le_plus_proche, distance_m)))

bdroe <- bdroe3

# Mise à jour Ouvrages prioritaires

bdroe <- bdroe %>% 
  dplyr::full_join(ouvrages_prioritaires, 
                   by = c("identifiant_roe" = "cdobstecou"))

# Mise à jour spatiale ----

maj_roe <- bdroe %>%
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
    ouvrage_prioritaire
  )



# examen des duplicats ---------
identifiants_roe_dupliques <- maj_roe %>% 
  sf::st_drop_geometry() %>% 
  group_by(identifiant_roe) %>% 
    tally() %>% 
  filter(n > 1) %>% 
  pull(identifiant_roe)

maj_roe_avec_duplicats <- maj_roe %>% 
  filter(identifiant_roe %in%  identifiants_roe_dupliques)

# fin examen des duplicats


# ajout des informations liste 2 non renseignées -------
maj_roe_l2 <- maj_roe %>%
  st_join(tampon_liste2) %>%
  mutate(long_Esp_arrete = str_length(coalesce(Esp_arrete, "0"))) %>% 
  group_by(identifiant_roe) %>% 
    filter(long_Esp_arrete == max(long_Esp_arrete)) %>% 
  select(identifiant_roe, Esp_arrete) %>% # on ne garde que les colonnes d'intérêt
  distinct() # dédoublonage


# sauvegarde ----
save(maj_roe,
     file = "data/outputs/maj_roe.RData")

## Mise à jour ZAP ----

st_crs(bdroe) == st_crs(zap_bzh)
st_crs(bdroe) == st_crs(zap_pdl)

st_geometry(roe_geom)
st_geometry(tampon_liste1)
st_geometry(tampon_liste2)

## Mise à jour Liste1 ----

maj_roe_l1 <- maj_roe %>%
  st_join(tampon_liste1) %>% 
  group_by(identifiant_roe) %>% 
  distinct() %>% 
  mutate(classement_liste_1 = case_when(
    !is.na(classement_liste_1) ~ classement_liste_1,
    is.na(classement_liste_1) & !is.na(Code_numer) ~ 'Oui',
    is.na(classement_liste_1) & is.na(Code_numer) ~ 'Non')) %>% 
  dplyr::select(!(c(Code_numer:CE_RESBIO)))

## Mise à jour Liste2 et espèces cibles ----

maj_roe1 <- maj_roe %>%
  st_join(tampon_liste2) %>%
  mutate(long_Esp_arrete = str_length(coalesce(Esp_arrete, "0")))

maj_roe2 <- maj_roe1 %>% 
  group_by(across(c(-Esp_arrete, - long_Esp_arrete))) 

maj_roe3 <- maj_roe2 %>%
  filter(long_Esp_arrete == max(long_Esp_arrete, na.rm = TRUE)) %>% 
  distinct(identifiant_roe)

maj_roe_spl2 <- maj_roe3 %>%
  mutate(classement_liste_2 = case_when(
    !is.na(classement_liste_2) ~ classement_liste_2,
    is.na(classement_liste_2) & !is.na(Esp_arrete) ~ 'Oui',
    is.na(classement_liste_2) & is.na(Esp_arrete) ~ 'Non')) %>% 
  mutate(especes_cibles = case_when(
    !is.na(especes_cibles) ~ especes_cibles,
    (is.na(especes_cibles) | especes_cibles == "") ~ Esp_arrete))  %>% 
  dplyr::select(!(c(fid:Lamproie_m, long_Esp_arrete)))

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
  filter(maj_roe, (is.na(fpi_nom1) | fpi_nom1 == "") &
           (is.na(fpi_nom2) | fpi_nom2 == "") &
           (is.na(fpi_nom3) | fpi_nom3 == "") &
           (is.na(fpi_nom4) | fpi_nom4 == "") &
           (is.na(fpi_nom5) | fpi_nom5 == "") &
           (is.na(mesure_corrective_devalaison_equipement) | mesure_corrective_devalaison_equipement == "") & 
           (is.na(mesure_corrective_montaison_equipement)) | mesure_corrective_montaison_equipement == "") %>% 
  mutate(manque_fip = "Oui") %>% 
  select(identifiant_roe, manque_fip) %>% 
  sf::st_drop_geometry()

manque_atg_l2 <-
  filter(maj_roe, is.na(avis_technique_global) & classement_liste_2 == "Oui" ) %>% 
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
  
# Mise à jour manque_l2

bdroe_maj <- bdroe_maj %>% 
  mutate(manque_l2 = ifelse(
    (classement_liste_2 == "Oui" & 
      (manque_etat == 'Oui' | 
       manque_type == 'Oui' | 
       manque_hc == 'Oui' | 
       non_valides == 'Oui' | 
       manque_fip == 'Oui')), 
    'Oui', ''))

# Mise à jour manque_op

bdroe_maj <- bdroe_maj %>% 
  mutate(manque_op = ifelse(
    (ouvrage_prioritaire == "Oui" & 
       (manque_etat == 'Oui' | 
          manque_type == 'Oui' | 
          manque_hc == 'Oui' | 
          non_valides == 'Oui' | 
          manque_fip == 'Oui')), 
    'Oui', ''))

# Sauvegarder la couche bdroe_maj

sf::write_sf(obj = bdroe_maj, dsn = "data/outputs/BDROE_interne_BZH_PDL_20230402.gpkg")
