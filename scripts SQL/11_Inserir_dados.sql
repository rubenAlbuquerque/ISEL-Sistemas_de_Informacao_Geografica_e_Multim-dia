DELETE FROM pp;
DELETE FROM efeito_obj;
DELETE FROM objecto_movel;
DELETE FROM cinematica_hist;
DELETE FROM cinematica;

DELETE FROM efeito_obj;
DELETE FROM objecto_movel;

-- tipo_terreno
-- terreno
-- spatial_ref_sys
-- rio
-- gps_ponto
-- pp;
-- efeito_obj;
-- objecto_movel;
-- cinematica_hist;
-- cinematica;

select * from tipo_terreno
select * from terreno
select * from spatial_ref_sys
select * from rio
select * from gps_ponto
select * from pp
select * from efeito_obj;
select * from objecto_movel
select * from cinematica_hist
select * from cinematica

-- 10
-- TIPO_TERRENO
-- INSERT INTO tipo_terreno( id_tipo_terreno )
-- VALUES('Rio');
-- INSERT INTO tipo_terreno( id_tipo_terreno )
-- VALUES('Floresta');
-- INSERT INTO tipo_terreno( id_tipo_terreno )
-- VALUES('Deserto');
-- INSERT INTO tipo_terreno( id_tipo_terreno )
-- VALUES('Tundra');
-- INSERT INTO tipo_terreno( id_tipo_terreno )
-- VALUES('Lago');

INSERT INTO tipo_terreno( id_tipo_terreno )
VALUES
    ('Rio'),
    ('Floresta'),
    ('Deserto'),
    ('Tundra'),
    ('Lago')
;

-- RIO
INSERT INTO rio( id_rio, id_tipo_terreno, nivel, g_rio )
VALUES
    (1, 'Rio', 5, ST_GeomFromText('LINESTRING(50 200, 125 199, 163 169, 175 124, 208 112, 270 100)')),
    (2, 'Rio', 5, ST_GeomFromText('LINESTRING(60 50, 119 70, 125 100, 150 115, 176 94, 181 50, 170 26)'))
;

-- TERRENO
INSERT INTO terreno( id_terreno, id_tipo_terreno, nivel, g_terreno )
VALUES
    (1, 'Floresta', 0, ST_GeomFromText('POLYGON((25 180, 30 200, 50 215, 90 175, 82 145, 30 125, 25 180))')),
    (2, 'Deserto', 1, ST_GeomFromText('POLYGON((50 202, 75 215, 155 210, 178 176, 175 130, 110 135, 60 155, 50 202))')),
    (3, 'Tundra', 0, ST_GeomFromText('POLYGON((155 161, 225 178, 270 175, 271 125, 170 51, 150 75, 132 120, 155 161))')),
    (4, 'Floresta', 1, ST_GeomFromText('POLYGON((179 100, 219 120, 255 119, 285 108, 284 59, 259 25, 218 17, 178 49, 179 100))')),
    (5, 'Deserto', 0, ST_GeomFromText('POLYGON((41 50, 84 82, 160 88, 202 62, 203 29, 161 12, 53 25, 41 50))')),
    (6, 'Tundra', 2, ST_GeomFromText('POLYGON((50 75, 50 128, 70 163, 165 150, 170 101, 120 66, 50 75))')),
    (7, 'Lago', 3, ST_GeomFromText('POLYGON((68 113, 73 129, 87 134, 100 126, 113 115, 108 83, 80 89, 68 113))')),
    (8, 'Floresta', 4, ST_GeomFromText('POLYGON((79 108, 76 118, 87 124, 93 116, 90 105, 79 108))'))
;

-- todos os terrenos ordenados por nivel
INSERT INTO terrenos_rios ( id_tipo_terreno, nivel, g_geo )
    SELECT t.id_tipo_terreno, t.nivel, t.g_terreno as g_geo
    FROM terreno t
    ORDER BY t.nivel
;

-- todos os rios ordenados por nivel, e com um buffer de K = 5
INSERT INTO terrenos_rios ( id_tipo_terreno, nivel, g_geo )
SELECT r.id_tipo_terreno, r.nivel, ST_Buffer(r.g_rio, 5) as g_geo
FROM rio r
;

-- indicação dos locais inicias dos objectos moveis e as suas cinematicas (orientacao, velocidade, aceleracao) iniciais
INSERT INTO cinematica ( id, orientacao, velocidade, aceleracao, g_posicao )
VALUES
    (1, 0, ((0, 0), 0), ((-0.1, 0.1), 0), ST_GeomFromText('POINT(170 30)')),
    (2, 0, ((0, 0), 0), ((-0.1, 0.1), 0), ST_GeomFromText('POINT(230 70)'))
;

-- indicação dos objetos perseguidor e alvo
INSERT INTO pp( id_perseguidor, id_alvo )
VALUES( 1, 2 );



INSERT INTO objecto_movel ( id, nome, id_cinematica, norma_vel_max, boost, g_geo )
VALUES
    (1, 'Lebre', 1, 5, 1, ST_Scale(ST_GeomFromText('POLYGON((0 0, 0 1, 0 2, 1 2, 1 3, 2 3, 2 4, 3 4, 3 5, 4 5, 5 5, 6 5, 6 6, 7 6, 7 7, 8 7, 8 8, 9 8, 9 9, 10 9, 11 9, 11 8, 11 7, 10 7, 10 6, 9 6, 8 6, 8 5, 7 5, 7 4, 6 4, 6 3, 6 2, 6 1, 5 1, 5 0, 4 0, 3 0, 2 0, 1 0, 0 0))'), 0.5, 0.5)),
    (2, 'Tartaruga', 2, 5, 1, ST_Scale(ST_GeomFromText('POLYGON((1 0, 1 1, 1 2, 0 2, 0 3, 1 3, 1 4, 1 5, 2 5, 2 6, 3 6, 3 7, 4 7, 5 7, 5 6, 6 6, 6 5, 7 5, 7 6, 8 6, 9 6, 9 5, 10 5, 10 4, 10 3, 9 3, 9 2, 8 2, 7 2, 7 1, 7 0, 6 0, 5 0, 5 1, 4 1, 3 1, 3 0, 2 0, 1 0))'), 0.5, 0.5))
;

-- GATO: ST_Scale(ST_GeomFromText('POLYGON((2 0, 
-- INSERT INTO objecto_movel ( id, nome, id_cinematica, norma_vel_max, boost, g_geo )
-- VALUES
--     (3, 'GATO', 1, 5, 1, ST_Scale(ST_GeomFromText('POLYGON((0 6, 0 7, 0 2, 1 2, 1 3, 2 3, 2 4, 3 4, 3 5, 4 5, 5 5, 6 5, 6 6, 7 6, 7 7, 8 7, 8 8, 9 8, 9 9, 10 9, 11 9, 11 8, 11 7, 10 7, 10 6, 9 6, 8 6, 8 5, 7 5, 7 4, 6 4, 6 3, 6 2, 6 1, 5 1, 5 0, 4 0, 3 0, 2 0, 1 0, 0 0))'), 0.5, 0.5)),
--     (4, 'PASSARO', 2, 5, 1, ST_Scale(ST_GeomFromText('POLYGON((1 0, 1 5, 0 2, 0 2, 0 3, 1 3, 3 4, 7 5, 2 5, 2 6, 3 6, 3 7, 4 7, 5 7, 5 6, 6 6, 6 5, 7 5, 7 6, 8 6, 9 6, 9 5, 10 5, 10 4, 10 3, 9 3, 9 2, 8 2, 7 2, 7 1, 7 0, 6 0, 5 0, 5 1, 4 1, 3 1, 3 0, 2 0, 1 0))'), 0.5, 0.5))
-- ;

UPDATE objecto_movel
    SET g_geo = ST_Translate(o.g_geo, ST_X(c.g_posicao) - ST_X(ST_Centroid(o.g_geo)), ST_Y(c.g_posicao) - ST_Y(ST_Centroid(o.g_geo)))
    FROM objecto_movel o, cinematica c
    WHERE o.id = c.id AND objecto_movel.id = o.id
;


-- INSERT INTO objecto_movel ( id, nome, id_cinematica, norma_vel_max, boost, g_geo )
-- VALUES
--     (3, 'Gato', 1, 5, 1, ST_Scale(ST_GeomFromText('POLYGON((2 0, 2 2, 1 2, ))'), 0.5, 0.5))
-- ;


UPDATE objecto_movel
SET g_geo = ST_GeomFromText('POLYGON((0.5488 5.6665, -0.0587 6.7032, -1.0676 6.6023, -1.4039 5.7784, -1.1303 5.3882, 0.4663 5.5920, -0.2016 1.7891, -0.7053 0.4339, -1.6904 1.2432, -0.7221 2.2195, -2.4154 1.2141, -0.8279 2.4973, -3.2488 1.1744, -0.9338 2.7486, -3.4472 1.5316, -1.2492 3.1037, -2.7329 2.4576, -3.3282 3.9657, -3.4076 5.1695, -4.5188 5.3018, -5.9740 9.6144, -2.3734 6.2688, -2.8419 6.9380, -2.1057 7.6072, -1.2135 8.0757, 0.4149 8.4772, 2.3110 8.4772, 4.2294 8.0757, 5.3002 7.3173, 4.8094 6.5365, 8.6016 10.0387, 6.7055 6.0011, 5.8802 5.8227, 6.1701 4.6627, 6.1255 3.2128, 4.5864 3.3243, 7.9547 2.2982, 4.4079 2.8336, 8.4455 1.5174, 4.1625 2.5213, 7.5978 1.2721, 4.1848 1.8967, 5.6348 1.2274, 4.6756 0.3575, 4.0000 0.0000, 1.3518 5.5550, 2.5564 5.4881, 3.6272 5.7781, 3.2702 6.6927, 2.3780 6.7596, 1.2849 5.6219, 4.0315 0.0703, 3.3145 -0.0731, 2.4302 -0.2046, 1.1157 -0.3599, -0.7126 0.3810, -0.1831 1.6054, 0.3112 1.1881, 1.4378 1.2049, 2.8018 1.4059, 2.2664 2.0974, 1.3965 2.2313, 0.7942 2.0974, 0.3629 1.8866, -0.1764 1.6589, 0.5488 5.6665))')
WHERE id = 1;


UPDATE objecto_movel
SET g_geo = ST_GeomFromText('POLYGON((226.4683 70.4007, 226.4431 70.8287, 226.6698 71.5589, 225.3353 71.3575, 224.1015 72.0877, 223.6987 72.9186, 223.9505 74.1020, 225.5871 75.1595, 227.4503 74.3789, 227.5258 73.5228, 227.4755 72.4150, 228.6085 72.7927, 229.7416 72.8682, 230.3207 73.0696, 231.3026 72.8934, 231.8566 72.3898, 232.7882 72.0625, 233.1155 72.7171, 233.6694 73.2962, 234.9032 73.7243, 236.1370 73.1200, 236.0362 71.9618, 235.5327 70.7028, 234.3996 70.8539, 233.2918 71.2316, 233.0652 69.2676, 232.9644 68.5878, 232.6119 67.9332, 232.3098 67.5555, 231.3782 67.4044, 230.9250 67.1778, 229.7667 67.1778, 228.8351 67.1526, 227.0474 67.6814, 226.5690 68.9151, 226.4683 70.4007))')
WHERE id = 2;


UPDATE objecto_movel
set nome= 'RATO'
where id = 2;

delete from objecto_movel
where nome = 4;


-- delete from objecto_movel
-- where id = 3;



-- insert into objecto_movel the diferent objects
INSERT INTO efeito_obj ( id_objeto, id_tipo_terreno, efeito )
VALUES
    (1, 'Rio',		0.1),
    (1, 'Floresta',	1),
    (1, 'Deserto',	0.8),
    (1, 'Tundra',	0.5),
    (1, 'Lago',		0.3),
    (2, 'Rio',		0.2),
    (2, 'Floresta',	0.8),
    (2, 'Deserto',	0.6),
    (2, 'Tundra',	1),
    (2, 'Lago',		0.4)
;











