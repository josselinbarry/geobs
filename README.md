# R_GEOBS : analyse et mise en évidence des manques de complétude dans les bases ROE et BDOE 

### Objectif :

Outil destiné aux agents de l'OFB pour cibler les données essentielles lacunaires dans les bases ROE et BDOE.

Ces manques de complétude sont des freins à la valorisation de ces bases de données (calculs des indicateurs d'étagement et de fractionnement dans le cadre du rapportage sur la continuité notamment). L'outil propose donc de mettre en évidence ces manques d'information, par ordre de priorité, pour faciliter leur intégration progressive par les agents.

### Traitements réalisés :

Certains ouvrages sont écartés préalablement de l'analyse car considérés comme non-prioritaires :
- Les ouvrages dont l'état est "Gelé",
- Les ouvrages considérés en « dérasement soldé », cumulant :
  - Un état "Entièrement détruit" (ou "dérasé" dans la BDOE),
  - Une hauteur de chute nulle,
  - Un Avis Technique Global (ATG) positif.

Les données considérées comme essentielles et sur lesquelles porte cette analyse sont les suivantes : 
- **Statut (non_valides)** : ouvrage en attente de validation,
- **Etat (manque_etat)** : pas d'état renseigné (Existant, En projet, En construction, Détruit entièrement ou Détruit partiellement),
- **Type (manque_type)** : pas de type renseigné (Barrage, Digue, Epis en rivière, Grille de pisciculture, Obstacle induit par un pont ou Seuil en rivière),
- **Franchissement piscicole (manque_fip)** : pas de franchissement piscicole renseigné (Absence de passe, Ascenseur à poisson, Autre type de passe, Ecluse à poisson, Exutoire de dévalaison, Passe à Anguille, Passe à bassins successifs, Passe à ralentisseurs, Pré-barrage, Rampe, Rivière de contournement ou Type de dispositif (piscicole) inconnu),
- **Hauteur de chute (manque_hc)** : pas de hauteur de chute renseignée (Hauteur de chute ou classe de hauteur de chute non renseignée dans le ROE, la BDOE et ICE). 

Afin de prioriser les renseignements à apporter, l'outil met en évidence les ouvrages pour lesquels au moins l'une de ces données est lacunaire lorsqu'ils sont considérés commme Ouvrage Prioritaire ou lorsqu'ils sont situés sur un tronçon classé en Liste 2 au titre de l'article L.214-17 du CE :
- **Manque sur Ouvrage prioritaire (manque_op)**,
- **Manque sur ouvrage situé en Liste 2 (manque_l2)**, 
- **Mise en évidence des "ouvrages dérasés soldés" (derasement_solde)**.

Deux dernières analyses, plus secondaires, viennent compléter ces premiers éléments : 
- *Pas d'Avis Technique Global (ATG) pour un ouvrage situé sur un tronçon classé en Liste 2* au titre de l'article L.214-17 du CE (manque_atg_l2),
- *Pas de cohérence entre la hauteur de chute (nulle), l'état (entièrement détruit ou dérasé) et l'ATG (non renseigné)* (mec_hc_atg).

### Export des résultats :

L'outil propose enfin trois exports de données :

- Deux couche géographiques (au format géopackage) : 
  - Une couche dite **"BDROE interne"** issue de la jointure du ROE interne et de la BDOE, complétée des différents paramètres d'analyse,
  - Une couche des bassins versant des masses d'eau qui compile, sous forme de **synthèse par masse d'eau**, l'ensemble des manques identifiés.

- Une table qui compile, sous forme de **synthèse départementale**, l'ensemble des manques identifiés (au format .xlsx).

## Import des données 

#### ROE

La base de donnée ROE est diffusée, dans sa version interne, deux à trois fois par an. Chaque diffusion donne lieu à une mise à jour des différents éléments d'analyse, à l'aide de l'outil R_geobs.

#### BDOE

La BDOE est accesible depuis le site geobs : https://geobs.eaufrance.fr/geobs/export.action

#### Données de contexte

Pour générer son analyse, l'outil nécessite de disposer des données de contexte suivantes : 
- Couche géographique des tronçons classés en Liste 1 au titre de l'article L.214-17,
- Couche géographique des tronçons classés en Liste 2 au titre de l'article L.214-17, 
- Table des ouvrages classés comme Ouvrages Prioritaires,
- Couche géographique des Zones d'Action Prioritaires pour l'anguille européenne,
- Couche géographique des Schémas d'Amménagement et de Gestion de l'Eau (SAGE).

## Jointure et filtre des bases (ROE et BDOE, régions bretagne et pays de la loire)

L'outil assure la jointure des bases entre elles puis filtre les ouvrages situés dans les régions Bretagne et Pays de la Loire.

## Complément d'informations

### Classement en Liste 1 et Liste 2 au titre de l'article L214.17

L'information qui indique le rattachement d'un ouvrage à un tronçon classé en Liste 1  ou en Liste 2 au titre de l'article L.214-17 est stockée dans la BDOE (classement_liste_1 et classement_liste_2). Nous ne disposons donc pas de l'information pour l'ensemble des ouvrages inscrits dans le ROE.

L'outil permet de conserver l'information contenue dans le BDOE, quand elle existe, et à défaut renseigne l'information par intersection avec un tampon de 50m autour des listes respectives. Cette méthode peut conduire à inclure ou exclure des ouvrages par erreur.  

### Classement en Zone Prioritaire d'Action pour l'anguille

Cette information n'est pas recensée dans les bases ROE et BDOE, elle peut cependant être utile afin de prioriser les ouvrages.

L'outil assure une jointure spatiale avec la couche des ZAP et renseigne leur rattachement ou non à ces zones (zap_ang). 

### Ajout de l'information du SAGE de rattachement

Cette information n'est pas recensée dans les bases ROE et BDOE, elle peut cependant être utile afin de prioriser les ouvrages.

L'outil assure une jointure spatiale avec la couche des SAGE et renseigne le nom du SAGE de rattachement (sage_nom). 

## Calcul des indicateurs de complétude

### Données essentielles 

#### Non validés (non_valides)
Mise en évidence (0/1) des ouvrages dont le statut du ROE est NULL ou non validé (statut_nom).

<img width="400" alt="non_valides" src="https://github.com/josselinbarry/geobs/assets/129364893/0f3a150f-8ac8-4421-b808-39755af73a7c">

#### Type (manque_type)

Mise en évidence (0/1) des ouvrages dont le type du ROE est NULL (type_nom).

<img width="400" alt="manque_type" src="https://github.com/josselinbarry/geobs/assets/129364893/d470a243-38a4-4fcf-ba05-233f2c5d9385">

#### Etat (manque_etat)

Mise en évidence (0/1) des ouvrages dont l'Etat du ROE est NULL (etat_nom).

<img width="400" alt="manque_etat" src="https://github.com/josselinbarry/geobs/assets/129364893/8bb1c71a-834a-4cd9-9289-e66a7f23e28a">

#### Franchissement piscicole (manque_fip)

Mise en évidence (0/1) des ouvrages dont l'existance d'un amménagement de franchissement piscicole n'est pas connue dans le ROE (fpi_nom1, fpi_nom2, fpi_nom3, fpi_nom4 et fpi_nom5) et la BDOE (mesure_corrective_devalaison_equipement et mesure_corrective_montaison_equipement).

<img width="400" alt="manque_fip" src="https://github.com/josselinbarry/geobs/assets/129364893/a52604b6-ddb3-4ab6-a21b-c2ade0169806">

#### Hauteur de chute

Mise en évidence (0/1) des ouvrages dont l'existance d'un amménagement de franchissement piscicole n'est pas connue dans le ROE (hauteur_chute_etiage et hauteur_chute_etiage_classe), la BDOE (ouv_hauteur_chute_1, ouv_hauteur_chute_2, ouv_hauteur_chute_3, ouv_hauteur_chute_4 et ouv_hauteur_chute_5) et ICE (hauteur_chute_ICE).

<img width="400" alt="manque_hc" src="https://github.com/josselinbarry/geobs/assets/129364893/81ed2b95-9b6c-4423-930f-36828be8b6f9">

### Données de priorisation

#### Manque identifié en Liste 2 (manque_l2)

Mise en évidence (0/1) des ouvrages situés en Liste 2 et qui présentent au moins un manque identifié sur l'une des 5 données essentielles.

<img width="400" alt="manque_l2" src="https://github.com/josselinbarry/geobs/assets/129364893/3b53cd93-3164-42ad-ba07-ef959187baee">

#### Manque identifié sur Ouvrage Prioritaire (manque_op)

Mise en évidence (0/1) des ouvrages classés comme Ouvrages Prioritaires et qui présentent au moins un manque identifié sur l'une des 5 données essentielles.

<img width="400" alt="manque_op" src="https://github.com/josselinbarry/geobs/assets/129364893/79f138f8-5e5b-4e9b-91d6-fe42af2f68ad">

### Données complémentaires

#### Manque d'Avis Technique Global en Liste 2

Mise en évidence (0/1) des ouvrages situés en Liste 2 et qui ne dispose pas d'Avis Technique Global dans le BDOE (avis_technique_global).

<img width="400" alt="manque_atg_l2" src="https://github.com/josselinbarry/geobs/assets/129364893/8da72ab3-682a-48cd-8890-9462096c181b">

#### Besoin de mise en cohérence de l'Avis Technique Global, avec l'état et la hauteur de chute

Mise en évidence (0/1) des ouvrages indiqués comme dérasés dans la BDOE (ouv_derasement) ou entièrement détruits dans le ROE (etat_nom), dont la hauteur de chute est nulle dans le ROE, la BDOE ou ICE, et dont l’Avis Technique Global est NULL dans la BDOE (avis_technique_global).

<img width="400" alt="mec_hc_atg" src="https://github.com/josselinbarry/geobs/assets/129364893/40969641-aa24-4f99-bb55-a71c2250fa1d">

#### Mise en évidence des "ouvrages dérasés soldés"

Mise en évidence (0/1) des ouvrages indiqués comme dérasés dans la BDOE (ouv_derasement) ou entièrement détruits dans le ROE (etat_nom), dont la hauteur de chute est nulle dans le ROE, la BDOE ou ICE, et dont l’Avis Technique Global est positif dans la BDOE (avis_technique_global). Ils sont considérés comme « soldés » et ne sont donc pas priorisés.

<img width="400" alt="derasement_solde" src="https://github.com/josselinbarry/geobs/assets/129364893/bbed97b8-e1d1-487e-9dfb-22d3b9947dea">

#### Mise en évidence des ouvrages situés en ZAP

Mise en évidence (0/1) des ouvrages situés en Zone d'Action Prioritaire pour l'anguille (zap_ang).

<img width="400" alt="zap_ang" src="https://github.com/josselinbarry/geobs/assets/129364893/abfc7d0b-9762-4394-bbe1-6a0149836aee">

#### Ajout du SAGE de rattachement de l'ouvrage;

Ajout du nom du SAGE de rattachement de l'ouvrage (sage_nom).

## Export de la couche BDROE interne

L'outil permet enfin d'exporter une couche de la "BDROE interne" au format géopackage.

Cette couche est ensuite diffusée régionalement aux agents en charge de renseigner des bases ROE et BDOE, via un projet Qgis et une mise en forme dédiés. 

## Valorisation régionale des principales informations contenues dans les bases ROE et BDOE (EN COURS DE REALISATION)

### Etat

Répartition des ouvrages selon leur état renseigné :

<img width="400" alt="etat" src="https://github.com/josselinbarry/geobs/assets/129364893/3812c32b-62ab-40e1-bc42-2dcf0db2d7f3">

### Type

Répartition des ouvrages selon leur type renseigné.

<img width="400" alt="type" src="https://github.com/josselinbarry/geobs/assets/129364893/f8c90445-27f5-4fcc-91f5-a6e246f2d8a6">

### Hauteur de chute

Répartition des ouvrages selon leur hauteur de chute renseigné.

<img width="400" alt="Hauteur de chute" src="https://github.com/josselinbarry/geobs/assets/129364893/6284e3ac-9580-4630-aa08-474ed6dcf189">

### Usages

Répartition des ouvrages selon leurs usages renseignés.

<img width="400" alt="usages" src="https://github.com/josselinbarry/geobs/assets/129364893/c9125fea-3700-459a-9342-fc9aab4cba35">

### Avis Technique Global

Répartition des ouvrages selon leur Avis Technique Global renseigné.

<img width="400" alt="atg" src="https://github.com/josselinbarry/geobs/assets/129364893/9899499d-3347-4fa7-96e0-6e9be2ac3124">

### Ouvrage de franchissement piscicole

Répartition des ouvrages selon le système de franchissement piscicole renseigné.

<img width="400" alt="Franchissement piscicole" src="https://github.com/josselinbarry/geobs/assets/129364893/b4f58521-c2da-4274-8a79-d5d16107e1c0">

### Chronologie de remplissage (nouvel ouvrage, modification, hauteurs de chute, ...)

Dynamique de renseignement du champ Hauteur de chute. 

<img width="400" alt="dynamique_date_hauteur_chute" src="https://github.com/josselinbarry/geobs/assets/129364893/168eb8cf-2e31-43aa-ba28-91fa2f01cab7">


## Améliorations envisagées (en cours de réalisation)

### Finalisation du script "Valorisation régionale des principales informations contenues dans les bases ROE et BDOE"
### Encapsulage dans une fonction



Josselin BARRY, OFB, Juin 2023
