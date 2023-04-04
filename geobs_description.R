dim(bdoe)
str(bdoe)

# packages library


# Chargement données ---------------------------
#bdoe
bdoe_bzh <- read.csv(file = "C:/SIG/R/geobs/data/export_de_base_20230330.csv",
                  header = TRUE,
                  sep = ";",
                  dec = ".")

bdoe_pdl <- read.csv(file = "C:/SIG/R/geobs/data/export_de_base_20230330.csv",
                     header = TRUE,
                     sep = ";",
                     dec = ".")

roe_lb <- read.csv(file = "C:/SIG/R/geobs/data/lb_temp20221219.csv",
                  header = TRUE,
                  sep = ";",
                  dec = ".",
                  fileEncoding = "utf8")

roe_sn <- read.csv(file = "C:/SIG/R/geobs/data/sn_temp20221219.csv",
                   header = TRUE,
                   sep = ";",
                   dec = ".",
                   encoding = "utf8")

#summarise quartiles hauteur de chute


#quart_hc <- summarise(bdoe_bzh, quant = quantile(ouv_hauteur_chute_1, probs = c(0.25, 0.5, 0.75), na.rm = T))

#group by

table_stat_roe2 <- roe_lb %>%
group_by(dept_code) %>%
summarise(moy_hc = mean(table_stat_roe2, hauteur_chute_etiage, na.rm = T))

  
rm(table_stat_roe)

#mise à jour spatiale
tampon_liste2 <- sf::read_sf(file = "C:/SIG/R/geobs/data/Liste2_LB_2018_holobiotiques.shp")

tampon_liste1 <- sf::read_sf(file = "C:/SIG/R/geobs/data/xxx.shp")

zap_pdl <- sf::read_sf(file = "C:/SIG/R/geobs/data/xxx.shp")

zap_bzh <- sf::read_sf(file = "C:/SIG/R/geobs/data/xxx.shp")

sage <- sf::read_sf(file = "C:/SIG/R/geobs/data/xxx.shp")

departement <- sf::read_sf(file = "C:/SIG/R/geobs/data/xxx.shp")

shapefile <- sf::read_sf(file = "C:/SIG/R/geobs/data/xxx.shp")

# Jointure ROE et BDOE ---------------------------


# Mise à jour Liste1 ---------------------------


# Mise à jour Liste2 et espèces cibles ---------------------------


# Mise à jour Sage ---------------------------


# Mise à jour ZAP ---------------------------


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

