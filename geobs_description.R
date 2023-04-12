dim(objet)
str(objet)
rm(objet)
mutate()
select()
filter()

# packages library

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

# Chargement données ---------------------------
#bdoe

bdoe_bzh <- data.table::fread(file = "data/export_de_base_20230330.csv")

bdoe_pdl <- data.table::fread(file = "data/export_de_base_20230330.csv")

#roe

roe_lb <- data.table::fread(file = "data/lb_temp20221219.csv",
                            encoding = "Latin-1",
                            colClasses = c("date_creation" = "character"))

roe_sn <- data.table::fread(file = "data/sn_temp20221219.csv",
                            encoding = "Latin-1",
                            colClasses = c("date_creation" = "character"))

roe_lb <- readr::read_csv(file = "data/lb_temp20221219.csv",
                          locale(encoding = "UTF-8"),
                           #colClasses = c("date_creation" = "character")
                           )

roe_sn <- readr::read_csv2(file = "data/sn_temp20221219.csv",
                            #encoding = "Latin-1",
                            #colClasses = c("date_creation" = "character")
                           )
#?? fusionner les tables

roe_lb_sn <- dplyr::bind_rows(roe_lb, roe_sn)

bdoe_dr2 <- dplyr::bind_rows(bdoe_bzh, bdoe_pdl)

# import données de contexte

liste2 <- sf::read_sf(dsn = "data/Liste2_LB_2018_holobiotiques.gpkg")

tampon_liste2 <- sf::st_buffer(liste2, dist = 100)

liste1 <- sf::read_sf(dsn = "data/Liste1_214.17.gpkg")
tampon_liste1 <- sf::st_buffer(liste1, dist = 100)

zap_pdl <- sf::read_sf(dsn = "data/Zone_Prioritaire_Anguille_PDL.gpkg")

zap_bzh <- sf::read_sf(dsn = "data/zap_anguille_bzh.gpkg")

sage <- sf::read_sf(dsn = "data/Sage.gpkg")

departement <- sf::read_sf(dsn = "data/xxx.shp")

# Jointure ROE et BDOE ---------------------------

jointure_bdroe <- roe_lb_sn %>% 
  dplyr::full_join(bdoe_bzh, 
                   by = c("identifiant_roe" = "cdobstecou"))

doublons_roe_jointure <- jointure_bdroe %>% 
  group_by(identifiant_roe) %>% 
  tally() %>% 
  filter(n > 1)

doublon_bdoe <- bdoe_bzh %>% 
  group_by(cdobstecou) %>% 
  tally() %>% 
  filter(n > 1)

doublon_roe <- roe_lb %>% 
  group_by(identifiant_roe) %>% 
  tally() %>% 
  filter(n > 1)

#mise à jour spatiale

# Mise à jour Liste1 ---------------------------

faire une jointure spatiale de tampon_liste_1 sur la bd_roe.
Sélectionner les objets dont le champ classement_liste_1 est null mettre 'Oui' pour ceux qui intersectent avec le tampon_liste_1, 'Non' pour les autres 

  
roe_geom <- roe_lb_sn %>% 
st_as_sf(coords = c("x_l93", "y_l93"), remove = FALSE, crs = 2154) 
  
roe_geom %>% 
  mapview::mapview()

roe_geom %>% 
  st_drop_geometry() %>% 
  View()

plot(st_geometry(roe_geom))


test_jointure_satiale <- st_join(roe_lb_sn, tampon_liste1, join = st_intersects)

# Mise à jour Liste2 et espèces cibles ---------------------------
faire une jointure spatiale de tampon_liste_2 sur la bd_roe.
Sélectionner les objets dont le champ classement_liste_2 est null mettre 'Oui' pour ceux qui intersectent avec le tampon_liste_1 et mettre à jour le champs especes_cibles à partir du champ join Esp_arrete, 'Non' pour les autres,  


# Mise à jour Sage ---------------------------
faire une jointure spatiale de sage sur la bd_roe
Sélectionner les objets dont le champ sage est null

# Mise à jour ZAP ---------------------------

# mapview::mapview(tampon_liste2)

mapview::mapview(zap_bzh)

mapview::mapview(tampon_liste2)

# alternative carto

ggplot(data = tampon_liste2) + geom_sf()

#alternative carto 2

carte_sage <- st_read(dsn = "data/sage.gpkg")
plot(carte_sage)

# Calcul indicateurs de complétude

#type d'ouvrage

ggplot(data = bdoe_bzh, 
       aes(x = ouv_type_nom)) +
  geom_bar(fill = "blue") +
  coord_flip() +
  labs(x = "Type d'ouvrage",
       y = "Nombre d'ouvrages",
       title = "Type d'ouvrage")
#fpi
ggplot(data = roe_lb, 
       aes(x = fpi_nom1)) +
  geom_bar(fill = "blue") +
  coord_flip() +
  labs(x = "Type d'ouvrage",
       y = "Nombre d'ouvrages",
       title = "Type d'ouvrage")

###statut/etat
ggplot(data = roe_lb, 
       aes(x = etat_nom)) +
  geom_bar(fill = "blue") +
  coord_flip() +
  labs(x = "Statut de l'ouvrage",
       y = "Nombre d'ouvrages",
       title = "Statut")

#hauteur de chute
ggplot(data = bdoe_bzh, 
       aes(y = ouv_hauteur_chute_1)) +
  geom_histogram(fill = "blue") +
  labs(y = "Hauteur de chute",
       x = "Nombre d'ouvrages",
       title = "Hauteur de chute")

#date d'observation##
ggplot(data = roe_lb, 
       aes(x = date_modification)) +
  geom_histogram(fill = "blue") +
  labs(x = "Date de l'observation",
       y = "Nombre d'ouvrages",
       title = "Hauteur de chute")

#arasement
ggplot(data = bdoe_bzh, 
       aes(x = ouv_arasement)) +
  geom_bar(fill = "blue") +
  coord_flip() +
  labs(x = "Arasement",
       y = "Nombre d'ouvrages",
       title = "Arasement")

#derasement
ggplot(data = bdoe_bzh, 
       aes(x = ouv_derasement)) +
  geom_bar(fill = "blue") +
  coord_flip() +
  labs(x = "Derasement",
       y = "Nombre d'ouvrages",
       title = "Derasement")

#ATG
ggplot(data = bdoe_bzh, 
       aes(x = avis_technique_global)) +
  geom_bar(fill = "blue") +
  coord_flip() +
  labs(x = "ATG",
       y = "Nombre d'ouvrages",
       title = "Avis Technique Global")

#Filtres

roe_22 <- filter(roe_lb, dept_code == 22 )

#manque_op <- filter(bdoe_bzh,

manque_type <- filter(bdoe_bzh, ouv_type_nom == "") 
manque_l2 <- filter(bdoe_bzh, classement_liste_2 == "Oui", manque_type)



manque_etat <- filter(bdoe_bzh, ouv_etat == "") 

manque_hc <- filter(bdoe_bzh, ouv_hauteur_chute_1 == "")
                    
manque_fip <- filter(bdoe_bzh, dispo_franch_piscicole_1 == "" )                    


#Résumé stat

summary(select(bdoe_bzh, avis_technique_global))
summary(select(bdoe_bzh, ouv_hauteur_chute_1))
summary(select(bdoe_bzh, ouv_date_hauteur_chute_1))
summarise(bdoe_bzh, ouv_hauteur_chute_1)

#tables de proportion

#summarise quartiles hauteur de chute


#quart_hc <- summarise(bdoe_bzh, quant = quantile(ouv_hauteur_chute_1, probs = c(0.25, 0.5, 0.75), na.rm = T))

#group by

table_stat_roe2 <- roe_lb %>%
  group_by(dept_code) %>%
  summarise(moy_hc = mean(table_stat_roe2, hauteur_chute_etiage, na.rm = T))



