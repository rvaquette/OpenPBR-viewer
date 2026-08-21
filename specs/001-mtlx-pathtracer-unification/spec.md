# Feature Specification: Pathtracer MaterialX Unification

**Feature Branch**: `001-le-code-source`

**Created**: 2026-08-20

**Status**: Draft

**Input**: User description: "Unifier le pathtracer legacy du viewer OpenPBR avec une génération MaterialX pour rendre le rendu pathtracé utilisable avec différents matériaux (OpenPBR, Standard Surface, Disney, etc.), via adaptations GLSL et éventuellement une nouvelle classe C++/WASM."

## Clarifications

### Session 2026-08-20

- Q: Quel comportement adopter pour un matériau non totalement pris en charge par le pathtracer? -> A: Echec strict avec erreur bloquante explicite.
- Q: Quelle étendue de support matériau est attendue au lancement? -> A: Support complet OpenPBR et support partiel Standard Surface/Disney.
- Q: Quel sous-ensemble fonctionnel Standard Surface/Disney est inclus au lancement? -> A: Diffuse, speculaire, transmission et clearcoat.
- Q: Quelle strategie d'echec appliquer pendant une campagne multi-materiaux? -> A: Echec par materiau avec poursuite de la campagne et rapport consolide.
- Q: Quel contenu minimum imposer au rapport consolide de campagne? -> A: Statut, categorie erreur, message, temps de rendu et couverture du sous-ensemble supporte.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pathtracer Compatible Multi-Matériaux (Priority: P1)

En tant qu’utilisateur du viewer, je veux charger un fichier MaterialX valide et obtenir un rendu pathtracé exploitable même si le matériau n’est pas OpenPBR, afin d’utiliser un flux unique de validation visuelle.

**Why this priority**: C’est la valeur principale du chantier, sans laquelle la migration vers un pathtracer MaterialX n’apporte pas de bénéfice fonctionnel.

**Independent Test**: Peut être testé indépendamment en chargeant un ensemble de matériaux de familles différentes et en vérifiant qu’une image pathtracée est produite sans blocage.

**Acceptance Scenarios**:

1. **Given** un fichier MaterialX Standard Surface valide, **When** l’utilisateur lance le mode pathtracer dédié, **Then** une image est rendue sans erreur bloquante.
2. **Given** un fichier MaterialX Disney valide, **When** l’utilisateur lance le rendu pathtracé, **Then** le matériau est interprété correctement sur le sous-ensemble de fonctionnalités officiellement supporté.

---

### User Story 2 - Pipeline de Génération Cohérent (Priority: P2)

En tant que développeur du pipeline, je veux une génération de matériaux adaptée au pathtracer afin d’éviter les divergences entre mode raster généré et mode pathtracé.

**Why this priority**: Sans pipeline cohérent, la maintenance et la correction des matériaux restent coûteuses et imprévisibles.

**Independent Test**: Peut être testé indépendamment en exécutant la génération puis en vérifiant que les artefacts attendus sont produits et intégrables au viewer.

**Acceptance Scenarios**:

1. **Given** une scène MaterialX compatible, **When** la génération est exécutée, **Then** les artefacts nécessaires au mode pathtracer sont générés avec les sections attendues.
2. **Given** une évolution du shader generator, **When** la génération est relancée, **Then** les résultats restent exploitables par le sous-répertoire pathtracer dédié sans adaptation manuelle systématique.

---

### User Story 3 - Validation Visuelle sur Corpus Legacy (Priority: P3)

En tant qu’intégrateur, je veux comparer rapidement les rendus sur les images et matériaux de référence existants afin de détecter les régressions fonctionnelles.

**Why this priority**: Cette étape sécurise l’adoption du nouveau flux et réduit le risque d’introduire des défauts silencieux sur certains matériaux.

**Independent Test**: Peut être testé indépendamment via une campagne de rendu sur le corpus legacy et une comparaison avec des critères de validation définis.

**Acceptance Scenarios**:

1. **Given** un corpus de matériaux et images de référence, **When** la campagne de rendu pathtracé est lancée, **Then** les cas conformes et non conformes sont identifiés de manière reproductible.
2. **Given** un matériau en échec durant la campagne, **When** l'erreur est détectée, **Then** la campagne continue pour les autres matériaux et le rapport final inclut l'échec diagnostiqué.
3. **Given** un matériau déjà connu comme fragile, **When** il est rendu via le nouveau pipeline, **Then** le système fournit un résultat exploitable ou un échec explicite traçable.

---

### Edge Cases

- Que se passe-t-il lorsqu’un fichier MaterialX utilise des nœuds non pris en charge par le flux pathtracer dédié?
- Si un matériau n’est pas totalement pris en charge, le système retourne un échec strict avec erreur bloquante explicite, sans fallback implicite.
- Si un materiau Standard Surface/Disney depasse le sous-ensemble diffuse/speculaire/transmission/clearcoat, le systeme retourne un echec explicite.
- Comment le système réagit si la génération produit un shader partiellement valide (image noire, NaN, divergence forte)?
- Comment le système gère des chemins d’assets (textures, includes) manquants ou incompatibles entre environnements?
- Que se passe-t-il lorsque le matériau contient des paramètres extrêmes (IOR, roughness, transmission) pouvant provoquer des instabilités numériques?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système MUST accepter un fichier MaterialX en entrée et tenter son exécution dans le mode pathtracer dédié.
- **FR-002**: Le système MUST assurer un support complet des matériaux OpenPBR via le flux commun de pathtracing.
- **FR-011**: Le système MUST assurer un support partiel explicite pour Standard Surface et Disney, limite au sous-ensemble diffuse, speculaire, transmission et clearcoat.
- **FR-003**: Le système MUST isoler les adaptations pathtracer MaterialX dans un sous-répertoire dédié pour éviter les régressions directes sur le flux legacy existant.
- **FR-004**: Le système MUST fournir une correspondance claire entre le résultat de génération et les points d’intégration attendus dans le rendu pathtracé.
- **FR-005**: Le système MUST échouer de manière explicite et diagnosticable lorsqu’un matériau ou une construction MaterialX est non supporté.
- **FR-006**: Le système MUST permettre de lancer une campagne de validation sur un corpus de matériaux et d’images de référence existantes.
- **FR-007**: Le système MUST produire un état de résultat par matériau (succès, échec) afin d’orienter les corrections.
- **FR-008**: Le système MUST préserver la stabilité du rendu pathtracé (pas de crash, pas de boucle non bornée) pour des entrées MaterialX valides.
- **FR-009**: Le système MUST autoriser l’évolution du composant de génération sans casser le contrat d’utilisation côté viewer.
- **FR-010**: Les utilisateurs MUST pouvoir sélectionner le mode pathtracer dédié MaterialX sans modifier manuellement les sources à chaque exécution.
- **FR-012**: Le système MUST continuer une campagne de validation après l'echec d'un matériau individuel et produire un rapport consolide de fin de campagne.
- **FR-013**: Le système MUST produire, pour chaque matériau du rapport consolidé, les champs statut, categorie d'erreur, message, temps de rendu et couverture du sous-ensemble supporte.

### Key Entities *(include if feature involves data)*

- **MaterialX Input**: Fichier de description de matériau avec graphes de nœuds, paramètres et références d’assets.
- **Pathtracer Shader Package**: Ensemble de shaders de pilotage et de surface nécessaires au rendu pathtracé MaterialX.
- **Generation Adapter**: Couche de transformation qui adapte la génération MaterialX au contrat attendu par le pathtracer.
- **Validation Corpus Entry**: Cas de test constitué d’un matériau, de ressources associées et d’un résultat attendu.
- **Validation Report**: Résultat consolidé par matériau, indiquant statut, categorie d'erreur, message, temps de rendu, couverture du sous-ensemble supporte et observations.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Au moins 90% des matériaux du corpus cible produisent une image pathtracée exploitable sans échec bloquant.
- **SC-002**: 100% des échecs de rendu observés sur le corpus produisent un diagnostic explicite exploitable par un développeur.
- **SC-003**: Le temps de mise en route d’un nouveau matériau via le flux dédié est inférieur à 10 minutes dans 95% des cas validés.
- **SC-004**: Le taux de réussite des scénarios P1 reste stable (variation maximale de 5%) sur trois exécutions de validation consécutives.
- **SC-005**: Au moins 80% des matériaux historiquement problématiques en legacy passent d’un état d’échec bloquant à un état exploitable ou diagnosticable.
- **SC-006**: 100% des entrees du rapport consolide contiennent les champs obligatoires statut, categorie d'erreur, message, temps de rendu et couverture.

## Assumptions

- La chaîne de génération des matériaux reste accessible avec une structure compatible durant le chantier.
- Le sous-répertoire ciblé pour les shaders pathtracer MaterialX est interprété par le viewer sans refonte complète de l’architecture de lancement.
- Le corpus legacy disponible est représentatif des usages prioritaires et sert de base de validation initiale.
- Les matériaux hors périmètre prioritaire peuvent être temporairement marqués comme non supportés, à condition que le diagnostic soit explicite.
- La première livraison vise la robustesse fonctionnelle et la couverture des cas principaux avant l’optimisation qualité/performance fine.
