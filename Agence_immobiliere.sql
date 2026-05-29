
CREATE DATABASE AGENCE_IMMOBILIERE;

use AGENCE_IMMOBILIERE;

CREATE TABLE proprietaires ( x
    id int auto_increment PRIMARY KEY,
    nom VARCHAR(100) NOT NULL
    );
    INSERT INTO proprietaires(nom) VALUES
('Jean Dupont'),
('Marie Kamga'),
('Paul Ndzi'),
('Sophie Talla');


CREATE TABLE locataires (
    id int auto_increment PRIMARY KEY,
    nom VARCHAR(100) NOT NULL
    );
    INSERT INTO locataires(nom) VALUES
('Eric Ndzi'),
('Vanessa Tchoua'),
('Kevin Momo'),
('Brenda Foko');


CREATE TABLE biens (
    id int auto_increment PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    loyer DECIMAL(10,2) NOT NULL,
    proprietaire_id int,
        CONSTRAINT fk_proprietaire
        FOREIGN KEY (proprietaire_id)
        REFERENCES proprietaires(id)
        ON DELETE CASCADE
);
INSERT INTO biens(type, loyer, proprietaire_id) VALUES
('Studio', 80000, 1),
('Appartement', 150000, 1),
('Villa', 350000, 2),
('Studio', 90000, 3),
('Appartement', 180000, 4);



CREATE TABLE contrats (
    id int auto_increment PRIMARY KEY,
    bien_id int,
    locataire_id int,
    date_debut DATE NOT NULL,
    date_fin DATE,

    CONSTRAINT fk_bien
        FOREIGN KEY (bien_id)
        REFERENCES biens(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_locataire
        FOREIGN KEY (locataire_id)
        REFERENCES locataires(id)
        ON DELETE CASCADE
);
INSERT INTO contrats(bien_id, locataire_id, date_debut, date_fin) VALUES
(1, 1, '2024-01-01', '2024-12-31'),
(2, 2, '2024-03-01', '2025-03-01'),
(3, 3, '2023-06-15', '2026-02-11'),
(4, 4, '2024-02-10', '2024-10-10');



DELIMITER &&
CREATE FUNCTION fn_loyer_annuel(bien_id int)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE loyer_mensuel DECIMAL(10,2);
    SELECT loyer
    INTO loyer_mensuel
    FROM biens
    WHERE id = bien_id;
    RETURN loyer_mensuel * 12;
END &&
DELIMITER &&;

CREATE VIEW vue_loyer_moyen_par_type as (SELECT type, AVG(loyer) AS loyer_moyen FROM biens GROUP BY type);

CREATE VIEW vue_proprietaires_avec_les_biens_les_plus_loues as (SELECT p.nom, COUNT(c.id) AS nb_locations FROM proprietaires p JOIN biens b ON p.id = b.proprietaire_id JOIN contrats c ON b.id = c.bien_id
GROUP BY p.nom
ORDER BY nb_locations DESC);

CREATE VIEW vue_revenu_annuel_total as (SELECT SUM(fn_loyer_annuel(id)) AS revenu_annuel
FROM biens);

CREATE VIEW vue_nbre_contracs_actifs as (SELECT COUNT(*) AS contrats_actifs
FROM contrats
WHERE date_fin IS NULL
   OR date_fin >= CURRENT_DATE);

create VIEW vue_moyenne_duree_contrats as(SELECT AVG(date_fin - date_debut) AS duree_moyenne FROM contrats WHERE date_fin IS NOT NULL);

create view vue_bien_avec_loyer_eleve as(SELECT * FROM biens WHERE loyer = ( SELECT MAX(loyer) FROM biens));

create view vue_nbre_contrats_par_annee as(SELECT EXTRACT(YEAR FROM date_debut) AS annee,COUNT(*) AS nombre_contrats FROM contrats GROUP BY annee ORDER BY annee);

create view vue_locataire_plus_contrats as(SELECT l.nom, COUNT(c.id) AS nb_contrats FROM locataires l JOIN contrats c ON l.id = c.locataire_id
GROUP BY l.nom
ORDER BY nb_contrats DESC);

create view vue_moy_loyers_par_proprietaire as(SELECT p.nom, AVG(b.loyer) AS moyenne_loyer FROM proprietaires p JOIN biens b ON p.id = b.proprietaire_id
GROUP BY p.nom);

create view vue_biens_vacants as(SELECT COUNT(*) AS biens_vacants FROM biens
WHERE id NOT IN (
    SELECT bien_id
    FROM contrats
    WHERE date_fin IS NULL
       OR date_fin >= CURRENT_DATE));

create view vue_distribution_loyers as(SELECT type,
       MIN(loyer) AS loyer_min,
       MAX(loyer) AS loyer_max,
       AVG(loyer) AS loyer_moyen
FROM biens
GROUP BY type);

create view vue_croiss_nombre_contrats_annee as(SELECT EXTRACT(YEAR FROM date_debut) AS annee, COUNT(*) AS total_contrats FROM contrats
GROUP BY annee
ORDER BY annee);

create view vue_contrats_resilies as(SELECT COUNT(*) AS contrats_resilies FROM contrats
WHERE date_fin < CURRENT_DATE);

create view vue_moy_loyers_mois as(SELECT DATE_FORMAT(date_debut, 'Month') AS mois, AVG(b.loyer) AS moyenne_loyer FROM contrats c
JOIN biens b ON c.bien_id = b.id
GROUP BY mois);

create view vue_proprietaire_revenu_eleve as(SELECT p.nom,SUM(b.loyer) AS revenu_total FROM proprietaires p JOIN biens b ON p.id = b.proprietaire_id
GROUP BY p.nom
ORDER BY revenu_total DESC
LIMIT 1);
