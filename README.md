# R_GEOBS : analyse et mise en évidence des manques de complétude des bases ROE et BDOE 

Outil destiné aux agents de l'OFB pour cibler les données essentielles lacunaires dans les bases ROE et BDOE.

Ces manques de complétude sont des freins à la valorisation de ces bases de données (calculs des indicateurs d'étagement et de fractionnement dans le cadre du rapportage sur la continuité notamment). L'outil propose donc de mettre en évidence ces manques d'information, par ordre de priorité, pour faciliter leur intégration progressive par les agents.

Les données considérées comme essentielles et sur lesquelles porte cette analyse sont les suivantes : 
- *Statut (non_valides)* : ouvrage en attente de validation,
- *Etat (manque_etat)* : pas d'état renseigné (Existant, En projet, En construction, Détruit entièrement ou Détruit partiellement),
- *Type (manque_type)* : pas de type renseigné (Barrage, Digue, Epis en rivière, Grille de pisciculture, Obstacle induit par un pont ou Seuil en rivière),
- *Franchissement piscicole (manque_fip)* : pas de franchissement piscicole renseigné (Absence de passe, Ascenseur à poisson, Autre type de passe, Ecluse à poisson, Exutoire de dévalaison, Passe à Anguille, Passe à bassins successifs, Passe à ralentisseurs, Pré-barrage, Rampe, Rivière de contournement ou Type de dispositif (piscicole) inconnu),
- *Hauteur de chute (manque_hc)* : pas de hauteur de chute renseignée (Hauteur de chute ou classe de hauteur de chute non renseignée dans le ROE, la BDOE et ICE). 

Afin de prioriser les renseignements à apporter, l'outil met en évidence les ouvrages pour lesquels au moins l'une de ces données est lacunaire lorsqu'ils sont considérés commme prioritaires (XXX) ou lorsqu'ils sont situés sur un tronçon classé en Liste 2 au titre de l'article L.214-17 :
- *Manque sur Ouvrage prioritaire (manque_op)*,
- *Manque sur ouvrage situé en Liste 2 (manque_l2)*, 
- *Mise en évidence des "ouvrages dérasés soldés" (derasement_solde)*.

Deux dernières analyses, plus secondaires, viennent compléter ces premiers éléments : 
- Pas d'Avis Technique Global (ATG) pour un ouvrage situé sur un tronçon classé en Liste 2 au titre de l'article L.214-17 (manque_atg_l2),
- Pas de cohérence entre la hauteur de chute (nulle), l'état (entièrement détruit ou dérasé) et l'ATG (non renseigné) (mec_hc_atg).

## Import des données (ROE, BDOE, données de contexte)

#### ROE

La base de donnée ROE est diffusée, dans sa version interne, deux à trois fois par an. Chaque diffusion donne lieu à une mise à jour des différents éléments d'analyse, à l'aide de l'outil R_geobs.

#### BDOE

La BDOE est accesible depuis le site geobs : https://geobs.eaufrance.fr/geobs/export.action

## Jointure et filtre des bases (ROE et BDOE, régions bretagne et pays de la loire)

L'outil assure la jointure des bases entre elles puis filtre les ouvrages concernés par les régions Bretagne et Pays de la Loire.

## Ajout d'information (L1, L2)

L'information qui indique le rattachement d'un ouvrage à un tronçon classé en Liste 1  ou en Liste 2 au titre de l'article L.214-17 est stockée dans la BDOE (classement_liste_1 et classement_liste_2).
Nous ne disposons donc pas de l'information pour l'ensemble des ouvrages inscrits dans le ROE.
L'outil permet de conserver l'information contenue dans le BDOE, quand elle existe, et à défaut renseigne l'information par intersection avec un tampon de 50m autour des listes respectives. Cette démarche peut inclure ou exclure des ouvrages par erreur.  

## Calcul des indicateurs de complétude

### Données essentielles 

#### Non validés (non_valides)

Mise en évidence (0/1) des ouvrages dont le statut du ROE est NULL ou non validé (statut_nom).

#### Type (manque_type)

Mise en évidence (0/1) des ouvrages dont le type du ROE est NULL (type_nom).

#### Etat (manque_etat)

Mise en évidence (0/1) des ouvrages dont l'Etat du ROE est NULL (etat_nom).

#### Franchissement piscicole (manque_fip)

Mise en évidence (0/1) des ouvrages dont l'existance d'un amménagement de franchissement piscicole n'est pas connue dans le ROE (fpi_nom1, fpi_nom2, fpi_nom3, fpi_nom4 et fpi_nom5) et la BDOE (mesure_corrective_devalaison_equipement et mesure_corrective_montaison_equipement).

#### Hauteur de chute

Mise en évidence (0/1) des ouvrages dont l'existance d'un amménagement de franchissement piscicole n'est pas connue dans le ROE (hauteur_chute_etiage et hauteur_chute_etiage_classe), la BDOE (ouv_hauteur_chute_1, ouv_hauteur_chute_2, ouv_hauteur_chute_3, ouv_hauteur_chute_4 et ouv_hauteur_chute_5) et ICE (hauteur_chute_ICE).

### Données de priorisation

#### Manque identifié en Liste 2 (manque_l2)

Mise en évidence (0/1) des ouvrages situés en Liste 2 et qui présentent au moins un manque identifié sur l'une des 5 données essentielles.

#### Manque identifié sur Ouvrage Prioritaire (manque_op)

Mise en évidence (0/1) des ouvrages classés comme Ouvrages Prioritaires et qui présentent au moins un manque identifié sur l'une des 5 données essentielles.

### Données complémentaires

#### Manque d'Avis Technique Global en Liste 2

Mise en évidence (0/1) des ouvrages situés en Liste 2 et qui ne dispose pas d'Avis Technique Global dans le BDOE (avis_technique_global).

#### Besoin de mise en cohérence de l'Avis Technique Global, avec l'état et la hauteur de chute

Mise en évidence (0/1) des ouvrages indiqués comme dérasés dans la BDOE (ouv_derasement) ou entièrement détruits dans le ROE (etat_nom), dont la hauteur de chute est nulle dans le ROE, la BDOE ou ICE, et dont l’Avis Technique Global est NULL dans la BDOE (avis_technique_global).

#### Mise en évidence des "ouvrages dérasés soldés"

Mise en évidence (0/1) des ouvrages indiqués comme dérasés dans la BDOE (ouv_derasement) ou entièrement détruits dans le ROE (etat_nom), dont la hauteur de chute est nulle dans le ROE, la BDOE ou ICE, et dont l’Avis Technique Global est positif dans la BDOE (avis_technique_global). Ils sont considérés comme « soldés » et ne sont donc pas priorisés.

## Export de la couche BDROE interne

L'outil permet d'exporter une couche de la "BDROE" interne au format géopackage.

Cette couche est ensuite diffusée aux agents en charge du renseignement des bases ROE et BDOE, via un projet Qgis et une mise en forme dédiée. 

## Valorisation régionale des principales informations contenues dans les bases ROE et BDOE (en cours de réalisation)

### Etat

Répartition des ouvrages selon leur état renseigné.

### Type

Répartition des ouvrages selon leur type renseigné.

### Hauteur de chute

Répartition des ouvrages selon leur hauteur de chute renseigné.

### Usages

Répartition des ouvrages selon leurs usages renseignés.

### Avis Technique Global

Répartition des ouvrages selon leur Avis Technique Global renseigné.

### Ouvrage de franchissement piscicole

Répartition des ouvrages selon le système de franchissement piscicole renseigné.

### Chronologie de remplissage (nouvel ouvrage, modification, hauteurs de chute, ...)

Dynamique de renseignement des champs dates. 

## Améliorations envisagées (en cours de réalisation)

### Ecriture des scripts "Valorisation régionale des principales informations contenues dans les bases ROE et BDOE"

### Jointure des données de contexte :
#### ZAP
#### SAGE

Josselin BARRY, OFB, Juin 2023
