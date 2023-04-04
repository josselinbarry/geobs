# Supprimer toutes les variables existantes
rm(list = ls())
# Création de mes variables taille et poids ; attention au point décimal
poids <- 91
taille <- 1.87
# Calcul de l'IMC : poids sur taille au carré
imc <- poids / (taille ^ 2)
# Affichage du résultat
print (imc)
