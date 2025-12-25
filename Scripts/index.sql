-- 1. Index B-tree classique pour les recherches fréquentes sur id_order ou id_utilisateur ou date_detection
CREATE INDEX idx_detection_anomalie_utilisateur ON detection_anomalie(id_utilisateur);
CREATE INDEX idx_detection_anomalie_order ON detection_anomalie(id_order);
CREATE INDEX idx_detection_anomalie_date ON detection_anomalie(date_detection);


-- 2. Index covering si tu as des requêtes qui récupèrent plusieurs colonnes fréquemment
-- Exemple : récupérer date_detection et commentaire pour un id_utilisateur
CREATE INDEX idx_detection_anomalie_utilisateur_covering 
ON detection_anomalie(id_utilisateur) INCLUDE(date_detection, commentaire);