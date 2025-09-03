# R_GEOBS : analyse et mise en évidence des manques de complétude des bases ROE et BDOE 

Outil destiné aux agents de l'OFB pour cibler les données essentielles lacunaires dans les bases ROE et BDOE.

Ces manques de complétude sont des freins à la valorisation de ces bases de données (calculs des indicateurs d'étagement et de fractionnement dans le cadre du rapportage sur la continuité notamment). L'outil propose donc de mettre en évidence ces manques d'information, par ordre de priorité, pour faciliter leur intégration progressive par les agents.

Les données considérées comme essentielles et sur lesquelles porte cette analyse sont les suivantes : 
- *Statut (non_valides)* : ouvrage en attente de validation,
- *Etat (manque_etat)* : pas d'état renseigné (Existant, En projet, En construction, Détruit entièrement ou Détruit partiellement),
- *Type (manque_type)* : pas de type renseigné (Barrage, Digue, Epis en rivière, Grille de pisciculture, Obstacle induit par un pont ou Seuil en rivière),
- *Franchissement piscicole (manque_fip)* : pas de franchissement piscicole renseigné (Absence de passe, Ascenseur à poisson, Autre type de passe, Ecluse à poisson, Exutoire de dévalaison, Passe à Anguille, Passe à bassins successifs, Passe à ralentisseurs, Pré-barrage, Rampe, Rivière de contournement ou Type de dispositif (piscicole) inconnu),
- *Hauteur de chute (manque_hc)* : pas de hauteur de chute renseignée (Hauteur de chute ou classe de hauteur de chute non renseignée dans le ROE, la BDOE et ICE). 

Afin de prioriser les renseignements à apporter, l'outil met en évidence les ouvrages pour lesquels au moins l'une de ces données est lacunaire lorsqu'ils sont considérés commme Ouvrages Prioritaires ou lorsqu'ils sont situés sur un tronçon classé en Liste 2 au titre de l'article L.214-17 :
- *Manque sur Ouvrage prioritaire (manque_op)*,
- *Manque sur ouvrage situé en Liste 2 (manque_l2)*, 
- *Mise en évidence des "ouvrages dérasés soldés" (derasement_solde)*.

Deux dernières analyses, plus secondaires, viennent compléter ces premiers éléments : 
- Pas d'Avis Technique Global (ATG) pour un ouvrage situé sur un tronçon classé en Liste 2 au titre de l'article L.214-17 (manque_atg_l2),
- Pas de cohérence entre la hauteur de chute (nulle), l'état (entièrement détruit ou dérasé) et l'ATG (non renseigné) (mec_hc_atg).

L'outil propose enfin deux exports de données sous forme de couche géographiques au format géopackage : 
- Une couche dite *"BDROE interne"* issue de la jointure du ROE interne et de la BDOE, complétée des différents paramètres d'analyse,
- Une couche des bassins versant des masses d'eau qui compile, sous forme de synthèse par masse d'eau, l'ensemble des manques identifiés pour les ouvrages qui leur sont rattachées.

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

<img width="1753" height="1240" alt="BRETAGNE_PAYS_DE_LA_LOIRE_manque_completude_NON_VALIDE" src="https://github.com/user-attachments/assets/e374ce20-267b-4c66-baa2-1c977b1777e1" />

#### Type (manque_type)

Mise en évidence (0/1) des ouvrages dont le type du ROE est NULL (type_nom).

<img width="1753" height="1240" alt="BRETAGNE_PAYS_DE_LA_LOIRE_manque_completude_TYPE" src="https://github.com/user-attachments/assets/6ef81097-358c-41de-93bc-ce20a368f456" />

#### Etat (manque_etat)

Mise en évidence (0/1) des ouvrages dont l'Etat du ROE est NULL (etat_nom).

<img width="1753" height="1240" alt="BRETAGNE_PAYS_DE_LA_LOIRE_manque_completude_ETAT" src="https://github.com/user-attachments/assets/ee372c11-008a-4d86-8e55-472ddbec1d81" />

#### Franchissement piscicole (manque_fip)

Mise en évidence (0/1) des ouvrages dont l'existance d'un amménagement de franchissement piscicole n'est pas connue dans le ROE (fpi_nom1, fpi_nom2, fpi_nom3, fpi_nom4 et fpi_nom5) et la BDOE (mesure_corrective_devalaison_equipement et mesure_corrective_montaison_equipement).

<img width="1753" height="1240" alt="BRETAGNE_PAYS_DE_LA_LOIRE_manque_completude_FIP" src="https://github.com/user-attachments/assets/67c1e4c5-0687-4b1b-a0ed-116d0695b113" />

#### Hauteur de chute

Mise en évidence (0/1) des ouvrages dont l'existance d'un amménagement de franchissement piscicole n'est pas connue dans le ROE (hauteur_chute_etiage et hauteur_chute_etiage_classe), la BDOE (ouv_hauteur_chute_1, ouv_hauteur_chute_2, ouv_hauteur_chute_3, ouv_hauteur_chute_4 et ouv_hauteur_chute_5) et ICE (hauteur_chute_ICE).

<img width="1753" height="1240" alt="BRETAGNE_PAYS_DE_LA_LOIRE_manque_completude_HC" src="https://github.com/user-attachments/assets/a51c12d5-9f6d-4d06-afc7-4fbf2f0dade6" />

### Données de priorisation

#### Manque identifié en Liste 2 (manque_l2)

Mise en évidence (0/1) des ouvrages situés en Liste 2 et qui présentent au moins un manque identifié sur l'une des 5 données essentielles.

<img width="1753" height="1240" alt="BRETAGNE_PAYS_DE_LA_LOIRE_manque_completude_L2" src="https://github.com/user-attachments/assets/d0646c54-7a13-4db0-aac4-d7471a5d0f26" />

#### Manque identifié sur Ouvrage Prioritaire (manque_op)

Mise en évidence (0/1) des ouvrages classés comme Ouvrages Prioritaires et qui présentent au moins un manque identifié sur l'une des 5 données essentielles.

<img width="1753" height="1240" alt="BRETAGNE_PAYS_DE_LA_LOIRE_manque_completude_OP" src="https://github.com/user-attachments/assets/ca8be7c1-ea80-47ad-bfbc-2fce93b7e99e" />

### Données complémentaires

#### Manque d'Avis Technique Global en Liste 2

Mise en évidence (0/1) des ouvrages situés en Liste 2 et qui ne dispose pas d'Avis Technique Global dans le BDOE (avis_technique_global).

<img width="1753" height="1240" alt="BRETAGNE_PAYS_DE_LA_LOIRE_manque_atg_L2" src="https://github.com/user-attachments/assets/d8afbb51-6e3f-4697-9df1-ac4939c4895b" />

#### Besoin de mise en cohérence de l'Avis Technique Global, avec l'état et la hauteur de chute

Mise en évidence (0/1) des ouvrages indiqués comme dérasés dans la BDOE (ouv_derasement) ou entièrement détruits dans le ROE (etat_nom), dont la hauteur de chute est nulle dans le ROE, la BDOE ou ICE, et dont l’Avis Technique Global est NULL dans la BDOE (avis_technique_global).

<img width="1753" height="1240" alt="BRETAGNE_PAYS_DE_LA_LOIRE_manque_coherence_etat_hc_atg" src="https://github.com/user-attachments/assets/353bd30d-a457-4506-b466-cee12f866c92" />

#### Mise en évidence des "ouvrages dérasés soldés"

Mise en évidence (0/1) des ouvrages indiqués comme dérasés dans la BDOE (ouv_derasement) ou entièrement détruits dans le ROE (etat_nom), dont la hauteur de chute est nulle dans le ROE, la BDOE ou ICE, OU dont l’Avis Technique Global est positif dans la BDOE (avis_technique_global). Ils sont alors considérés comme « soldés » et ne sont donc pas priorisés.

#### Mise en évidence des ouvrages situés en ZAP

Mise en évidence (0/1) des ouvrages situés en Zone d'Action Prioritaire pour l'anguille (zap_ang).

#### Ajout du SAGE de rattachement de l'ouvrage;

Ajout du nom du SAGE de rattachement de l'ouvrage (sage_nom).

## Export de la couche BDROE interne

L'outil permet enfin d'exporter une couche de la "BDROE interne" au format géopackage.

Cette couche est ensuite diffusée régionalement aux agents en charge de renseigner des bases ROE et BDOE, via un projet Qgis et une mise en forme dédiés. 

<img width="410" height="396" alt="legende_mise_en_qualite" src="https://github.com/user-attachments/assets/fadb56bc-d941-4630-88b2-98b2e705d304" />

## Couche de synthèse par masse d'eau

Production d'une couche des bassins versant des masses d'eau qui synthétise par masse d'eau, les principaux manques identifiés pour les ouvrages qui leur sont rattachés.

<img width="410" height="396" alt="etiquette_synthese" src="https://github.com/user-attachments/assets/0dab31f1-a293-4d27-ab8c-7387728b793a" />

## Valorisation régionale des principales informations contenues dans les bases ROE et BDOE

### Nombre total d'ouvrages

Répartition des ouvrages selon leur statut de validité.

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



**Josselin BARRY, OFB-DR Bretagne, Septembre 2025**
