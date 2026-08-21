# Feature Specification: WASM BXDF Replacement

**Feature Branch**: `002-le-code-wasm`

**Created**: 2026-08-21

**Status**: Draft

**Input**: User description: "Le code WASM MaterialX génère les fonctions BSDF, EDF et BRDF; ces fonctions doivent remplacer celles implémentées manuellement dans les fichiers legacy de type XXX_bXdf.glsl."

## Clarifications

### Session 2026-08-21

- Q: Quel comportement adopter quand les fonctions generees WASM sont absentes ou incompatibles? -> A: Echec strict avec diagnostic explicite, sans fallback legacy.
- Q: Quelle strategie de comparaison avant/apres utiliser pendant la validation? -> A: Comparaison manuelle uniquement, hors pipeline automatise.
- Q: Quand un ecart visuel doit-il etre considere critique pour la livraison? -> A: Divergence majeure d'energie globale, teinte dominante, ou perte de details principaux sur la zone materiau.
- Q: Quel contrat minimal des fonctions generees imposer au lancement? -> A: Aucun set universel obligatoire, evaluation au cas par cas selon le materiau.
- Q: Quel contenu minimum imposer au rapport de substitution par materiau? -> A: Statut, fonctions generees utilisees, cause d'echec, type d'ecart visuel, temps de rendu et version de generation WASM.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Substitution des BXDF Legacy (Priority: P1)

En tant qu’intégrateur rendu, je veux que le pathtracer utilise les fonctions de shading generees par le pipeline MaterialX WASM, selon les besoins du materiau, a la place des implementations legacy afin d'avoir un comportement materiau aligne sur la source generee.

**Why this priority**: C’est la valeur centrale de la demande: supprimer la duplication de logique legacy et fiabiliser le comportement via une source unique.

**Independent Test**: Peut être testé indépendamment en exécutant un rendu sur des matériaux représentatifs et en vérifiant que les chemins de calcul passent par les fonctions générées plutôt que par les anciens blocs legacy.

**Acceptance Scenarios**:

1. **Given** un matériau compatible avec la génération MaterialX, **When** le pathtracer est exécuté, **Then** les fonctions générées pertinentes pour ce matériau sont utilisées pour l’évaluation et l’échantillonnage.
2. **Given** une fonction legacy encore présente dans un fichier XXX_bXdf.glsl, **When** la substitution est activée, **Then** cette logique n’est plus utilisée dans le flux principal de rendu.
3. **Given** une fonction générée requise absente ou incompatible, **When** le rendu est lancé, **Then** le matériau est marqué en échec explicite et aucun fallback legacy implicite n’est appliqué.

---

### User Story 2 - Contrat d’Intégration Stable (Priority: P2)

En tant que développeur pipeline, je veux un contrat d’intégration clair entre génération WASM et pathtracer afin que l’évolution de la génération reste compatible sans corrections manuelles répétées.

**Why this priority**: Sans contrat explicite, les changements de génération peuvent casser silencieusement le rendu pathtracé.

**Independent Test**: Peut être testé indépendamment en régénérant les fonctions puis en validant que les points d’appel attendus restent valides et détectables automatiquement.

**Acceptance Scenarios**:

1. **Given** une nouvelle sortie de génération WASM, **When** elle est intégrée au pathtracer, **Then** les points d’entrée requis sont résolus sans modification manuelle des fichiers legacy.
2. **Given** une rupture de contrat dans la sortie générée, **When** la validation est lancée, **Then** un échec explicite et diagnosticable est remonté avant publication.

---

### User Story 3 - Validation de Non-Régression Visuelle (Priority: P3)

En tant que responsable qualité rendu, je veux comparer les résultats avant/après substitution sur le corpus existant afin de qualifier les écarts attendus et détecter les régressions critiques.

**Why this priority**: Le remplacement des fonctions de shading est sensible; une validation structurée réduit le risque de régression production.

**Independent Test**: Peut être testé indépendamment en lançant une campagne de rendu sur le corpus de référence puis en classifiant les écarts par sévérité.

**Acceptance Scenarios**:

1. **Given** un corpus de matériaux de référence, **When** la campagne avant/après est exécutée, **Then** chaque matériau dispose d’un statut de comparaison et d’un diagnostic.
2. **Given** un écart visuel critique détecté, **When** le rapport est généré, **Then** le cas est marqué bloquant pour la livraison.

---

### Edge Cases

- Que se passe-t-il si la génération WASM ne produit pas une ou plusieurs fonctions attendues pour un matériau donné?
- En cas d'absence ou d'incompatibilite des fonctions generees requises, le systeme retourne un echec explicite sans fallback vers les modules legacy.
- Comment le système se comporte-t-il si la signature d’une fonction générée change entre deux versions?
- Que se passe-t-il si les fonctions générées existent mais retournent des valeurs invalides (NaN, infini, énergie négative)?
- Comment le système réagit lorsqu’un matériau legacy n’a pas d’équivalent direct dans le flux généré?
- Un ecart visuel est critique s'il montre une divergence majeure d'energie globale, de teinte dominante, ou une perte de details principaux sur la zone materiau.
- Si un materiau ne requiert pas tout le set BSDF/EDF/BRDF, la validite est evaluee selon son contrat de fonctions declare, sans set universel impose.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système MUST utiliser les fonctions de shading generees par le pipeline MaterialX WASM dans le flux principal du pathtracer, selon le contrat declare pour chaque materiau.
- **FR-002**: Le système MUST désactiver l’utilisation des implémentations legacy XXX_bXdf.glsl dans le flux principal lorsqu’une version générée valide est disponible.
- **FR-003**: Le système MUST définir un contrat d’intégration explicite des points d’entrée générés requis par le pathtracer.
- **FR-014**: Le système MUST autoriser un contrat de fonctions generees variable selon le materiau, sans imposer un set BSDF/EDF/BRDF universel pour tous les cas.
- **FR-004**: Le système MUST détecter et signaler explicitement toute absence ou incompatibilité de fonction générée requise.
- **FR-011**: Le système MUST échouer explicitement au niveau matériau si une fonction générée requise est absente ou incompatible, sans fallback automatique vers les implémentations legacy.
- **FR-005**: Le système MUST permettre une campagne de validation avant/après sur un corpus de matériaux de référence.
- **FR-012**: Le système MUST garder la comparaison legacy hors pipeline automatise; toute comparaison avant/apres est executee manuellement en mode de validation dedie.
- **FR-006**: Le système MUST produire un rapport par materiau indiquant le statut de substitution, le statut de rendu, les fonctions generees utilisees, la cause d'echec, le type d'ecart visuel, le temps de rendu et la version de generation WASM.
- **FR-007**: Le système MUST bloquer la livraison quand un écart critique de rendu est détecté sur le périmètre défini.
- **FR-013**: Le système MUST classifier comme critique tout ecart montrant une divergence majeure d'energie globale, de teinte dominante, ou une perte de details principaux sur la zone materiau.
- **FR-008**: Le système MUST préserver la stabilité d’exécution (pas de crash, pas de boucle non bornée) pour les matériaux valides du périmètre.
- **FR-009**: Les utilisateurs MUST pouvoir exécuter le mode pathtracer avec substitution active sans modification manuelle des shaders legacy à chaque lancement.
- **FR-010**: Le système MUST fournir une traçabilité claire permettant d’identifier, pour chaque matériau, quelles fonctions générées ont été utilisées.

### Key Entities *(include if feature involves data)*

- **Generated Shading Function Set**: Ensemble des fonctions BSDF, EDF et BRDF produites par la chaîne MaterialX WASM pour un matériau.
- **Legacy BXDF Module**: Bloc de shading historique implémenté manuellement dans les fichiers XXX_bXdf.glsl.
- **Integration Contract**: Définition des points d’entrée, comportements attendus et règles de compatibilité entre génération et pathtracer.
- **Validation Corpus Entry**: Cas de test composé d’un matériau, de ses assets et de son statut attendu.
- **Substitution Report**: Rapport consolide des substitutions et resultats de validation par materiau, incluant statut, fonctions utilisees, causes d'echec, type d'ecart visuel, temps de rendu et version WASM.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% des matériaux du périmètre prioritaire utilisent les fonctions générées dans le flux principal quand elles sont valides.
- **SC-002**: 100% des incompatibilités de contrat de génération sont détectées avant livraison avec un diagnostic explicite.
- **SC-003**: Au moins 95% des rendus du corpus prioritaire se terminent sans échec bloquant après substitution.
- **SC-004**: 100% des matériaux du rapport disposent d’une traçabilité des fonctions utilisées et d’un statut de validation.
- **SC-005**: Le temps d’intégration d’une nouvelle génération sur le périmètre prioritaire est inférieur à 15 minutes dans 90% des exécutions de validation.
- **SC-006**: 100% des ecarts classes critiques dans les rapports respectent les criteres explicites energie globale, teinte dominante, details principaux.
- **SC-007**: 100% des entrees du rapport de substitution contiennent les champs obligatoires statut, fonctions utilisees, cause d'echec, type d'ecart visuel, temps de rendu et version WASM.

## Assumptions

- La chaîne MaterialX WASM continue de produire les fonctions de shading nécessaires au périmètre cible.
- Le pathtracer legacy reste la base d’exécution pendant la transition vers la substitution complète.
- Un corpus de matériaux de référence existe et peut être exécuté de manière répétable pour la validation.
- Les matériaux hors périmètre prioritaire peuvent être temporairement exclus à condition d’être explicitement signalés.
- Les critères d’écart critique de rendu sont définis et partagés avant décision de livraison.
