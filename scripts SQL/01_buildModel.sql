-- -- --  tabelas:
-- tipo_terreno
-- terreno
-- spatial_ref_sys
-- rio
-- gps_ponto
-- pp;
-- efeito_obj;
-- objecto_movel
-- cinematica_hist
-- cinematica

-- -- -- Estruturas
-- DROP TYPE IF EXISTS t_velocidade;
-- DROP TYPE IF EXISTS t_aceleracao;
-- DROP OPERATOR IF EXISTS *( t_vector, real );
-- DROP OPERATOR IF EXISTS *( real, t_vector );
-- DROP OPERATOR IF EXISTS +( t_vector, t_vector );
-- DROP TYPE IF EXISTS t_vector;



-- -- -- Funcoes
-- DROP FUNCTION IF EXISTS produto_vector_por_escalar( t_vector, real );
-- DROP FUNCTION IF EXISTS produto_escalar_por_vector( real, t_vector );
-- DROP FUNCTION IF EXISTS produto_vector_por_escalar_sql( t_vector, real );
-- DROP FUNCTION IF EXISTS soma_vector_vector( t_vector, t_vector );
-- DROP FUNCTION IF EXISTS normalizar( t_vector );
-- DROP FUNCTION IF EXISTS norma( t_vector );
-- DROP FUNCTION IF EXISTS novo_posicao( geometry, t_velocidade, real );
-- DROP FUNCTION IF EXISTS novo_orientacao( real, t_velocidade, real );
-- DROP FUNCTION IF EXISTS novo_velocidade( t_velocidade, t_aceleracao, real );
-- DROP FUNCTION IF EXISTS novo_aceleracao_linear( geometry, geometry, real );
-- DROP FUNCTION IF EXISTS obter_aceleracao_perseguidor( int, int, real );


-- -- -- views
-- DROP VIEW IF EXISTS v_novo_cinematica;






-- 00
-- Ligação à BD
DROP DATABASE IF EXISTS my_gis_ta;
-- SELECT current_database();
CREATE DATABASE my_gis_ta;

CREATE EXTENSION postgis;
SELECT postgis_version();

--01
-- Criar o Esquema Relacional
DROP TABLE IF EXISTS gps_ponto;
DROP TABLE IF EXISTS terreno;
DROP TABLE IF EXISTS rio;
DROP TABLE IF EXISTS hierarquia;
DROP TABLE IF EXISTS tipo_terreno;

CREATE TABLE tipo_terreno (
	id_tipo_terreno varchar primary key
);

CREATE TABLE rio (
	id_rio int primary key,
	id_tipo_terreno varchar,
	nivel int,
	constraint fk_id_tipo_terreno foreign key (id_tipo_terreno) references tipo_terreno(id_tipo_terreno)
);
SELECT AddGeometryColumn( '', 'rio', 'g_rio', 0, 'LINESTRING', 2 );


CREATE TABLE terreno (
	id_terreno int primary key,
	id_tipo_terreno varchar,
	nivel int,
	constraint fk_id_tipo_terreno foreign key (id_tipo_terreno) references tipo_terreno(id_tipo_terreno)
);
SELECT AddGeometryColumn( '', 'terreno', 'g_terreno', 0, 'POLYGON', 2 );



-- ??????????????????????????????
-- tabela para guardar todos os terrenos e rios num mesmo local, 
-- juntando o buffer dos rios com os poligonos dos terrenos

DROP TABLE IF EXISTS terrenos_rios;

CREATE TABLE terrenos_rios (
	id_tipo_terreno varchar,
	nivel int,
	constraint fk_id_tipo_terreno foreign key (id_tipo_terreno) references tipo_terreno(id_tipo_terreno)
);
SELECT AddGeometryColumn( '', 'terrenos_rios', 'g_geo', 0, 'POLYGON', 2 );



CREATE TABLE gps_ponto (
	id_ordem int,
	id_terreno int,
	constraint pk_gps_ponto primary key (id_ordem, id_terreno),
	constraint fk_id_terreno foreign key (id_terreno) references terreno(id_terreno)
);
SELECT AddGeometryColumn( '', 'gps_ponto', 'g_ponto', 0, 'POINT', 2 );



-- 02
-- Estender o Modelo Relacional com Novas Estruturas

DROP TYPE IF EXISTS t_velocidade;
DROP TYPE IF EXISTS t_aceleracao;
DROP OPERATOR IF EXISTS *( t_vector, real );
DROP OPERATOR IF EXISTS *( real, t_vector );
DROP OPERATOR IF EXISTS +( t_vector, t_vector );
DROP FUNCTION IF EXISTS produto_vector_por_escalar( t_vector, real );
DROP FUNCTION IF EXISTS produto_escalar_por_vector( real, t_vector );
DROP FUNCTION IF EXISTS produto_vector_por_escalar_sql( t_vector, real );
DROP FUNCTION IF EXISTS soma_vector_vector( t_vector, t_vector );
DROP FUNCTION IF EXISTS normalizar( t_vector );
DROP TYPE IF EXISTS t_vector;
DROP FUNCTION IF EXISTS norma( t_vector );


CREATE TYPE t_vector AS (
	x real,
	y real
);
CREATE TYPE t_velocidade AS (
	linear t_vector,
	angular real
);
CREATE TYPE t_aceleracao AS (
	linear t_vector,
	angular real
);

-- Estender o Modelo Relacional com Novas Funcoes
-- Produto de um vector por um escalar

CREATE OR REPLACE FUNCTION produto_vector_por_escalar( vec t_vector, v real )
	RETURNS t_vector
	AS $$
	DECLARE
		new_x real;
		new_y real;
	BEGIN
		new_x := vec.x * v;
		new_y := vec.y * v;
		RETURN (new_x, new_y);
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION produto_escalar_por_vector( v real, vec t_vector )
	RETURNS t_vector
	AS $$
	DECLARE
		new_x real;
		new_y real;
	BEGIN
		new_x := vec.x * v;
		new_y := vec.y * v;
		RETURN (new_x, new_y);
	END;
$$ LANGUAGE plpgsql;


-- Definição do Operador
CREATE OPERATOR * (
	leftarg = t_vector,
	rightarg = real,
	procedure = produto_vector_por_escalar,
	commutator = *
);

CREATE OPERATOR * (
	leftarg = real,
	rightarg = t_vector,
	procedure = produto_escalar_por_vector,
	commutator = *
);


-- Soma de dois vectores
CREATE OR REPLACE FUNCTION soma_vector_vector( vec_a t_vector, vec_b t_vector )
	RETURNS t_vector
	AS $$
	DECLARE
		new_x real;
		new_y real;
	BEGIN
		new_x := vec_a.x + vec_b.x;
		new_y := vec_a.y + vec_b.y;
		RETURN (new_x, new_y);
	END;
$$ LANGUAGE plpgsql;


-- Definição do Operador
CREATE OPERATOR + (
	leftarg = t_vector,
	rightarg = t_vector,
	procedure = soma_vector_vector,
	commutator = +
);


CREATE OR REPLACE FUNCTION norma( vec t_vector )
	RETURNS real
	AS $$
	DECLARE
	BEGIN
		RETURN sqrt(power(vec.x, 2) + power(vec.y, 2));
	END;
$$ LANGUAGE plpgsql;



-- Normalizar vector: dividir cada componente pela norma
CREATE OR REPLACE FUNCTION normalizar( vec t_vector )
	RETURNS t_vector
	AS $$
	DECLARE
		new_x real;
		new_y real;
	BEGIN
		new_x := vec.x / norma(vec);
		new_y := vec.y / norma(vec);
		RETURN (new_x, new_y);
	END;
$$ LANGUAGE plpgsql;


--03
-- Criar Estrutura de suporte 'a cinematica e 'a nocao de perseguicao
DROP TABLE IF EXISTS cinematica_hist CASCADE;
DROP TABLE IF EXISTS pp CASCADE;
DROP TABLE IF EXISTS cinematica CASCADE;


CREATE TABLE cinematica(
	id integer primary key,
	orientacao real,
	velocidade t_velocidade,
	aceleracao t_aceleracao
);
SELECT AddGeometryColumn( '', 'cinematica', 'g_posicao', 0, 'POINT', 2 );


-- Regista trajectos (i.e., historico da cinematica)
CREATE TABLE cinematica_hist(
	id_hist SERIAL PRIMARY KEY,
	id int,
	orientacao real,
	velocidade t_velocidade,
	aceleracao t_aceleracao,
	constraint fk_id_cinematica foreign key (id) references cinematica(id)
);
SELECT AddGeometryColumn( '', 'cinematica_hist', 'g_posicao', 0, 'POINT', 2 );


--04
-- Obter valores de 'cinematica' para um instante do tempo
DROP FUNCTION IF EXISTS novo_posicao( geometry, t_velocidade, real );
DROP FUNCTION IF EXISTS novo_orientacao( real, t_velocidade, real );
DROP FUNCTION IF EXISTS novo_velocidade( t_velocidade, t_aceleracao, real );

-- Obter a nova posicao do objecto no instante 'tempo'
CREATE OR REPLACE FUNCTION novo_posicao( g_posicao geometry, velocidade t_velocidade, tempo real )
	RETURNS geometry
	AS $$
	SELECT 
	ST_Translate( $1,
				(($2).linear * $3 ).x,
				(($2).linear * $3 ).y )
$$ LANGUAGE 'sql';


-- Obter a nova orientacao do objecto no instante 'tempo'
CREATE OR REPLACE FUNCTION novo_orientacao( orientacao real, velocidade t_velocidade, tempo real )
	RETURNS real
	AS $$
	DECLARE
		novo_orientacao real;
	BEGIN
		novo_orientacao := orientacao + velocidade.angular * tempo;
		RETURN novo_orientacao;
	END;
$$ LANGUAGE plpgsql;


-- Obter a nova velocidade do objecto no instante 'tempo'
CREATE OR REPLACE FUNCTION novo_velocidade( velocidade t_velocidade, aceleracao t_aceleracao, tempo real )
	RETURNS t_velocidade
	AS $$
	DECLARE
		novo_velocidade t_velocidade;
	BEGIN
		novo_velocidade.linear := velocidade.linear + aceleracao.linear * tempo;
		novo_velocidade.angular := velocidade.angular + aceleracao.angular * tempo;
		RETURN novo_velocidade;
	END;
$$ LANGUAGE plpgsql;


-- 05
-- Criar Estrutura de suporte 'a nocao de perseguicao
-- DROP TABLE IF EXISTS pp CASCADE;

-- Suporte a nocao de perseguicao
CREATE TABLE pp(
	id_perseguidor int,
	id_alvo int,
	constraint fk_id_perseguidor foreign key (id_perseguidor) references cinematica(id),
	constraint fk_id_alvo foreign key (id_alvo) references cinematica(id)
);

-- 06
-- Obter valores de 'cinematica' para uma 'perseguicao'
DROP VIEW IF EXISTS v_novo_cinematica;
DROP FUNCTION IF EXISTS novo_aceleracao_linear( geometry, geometry, real );
DROP FUNCTION IF EXISTS obter_aceleracao_perseguidor( int, int, real );


-- Obter a nova aceleracao linear do objecto para realizar uma perseguicao
CREATE OR REPLACE FUNCTION novo_aceleracao_linear( g_posicao_perseguidor geometry,
                                                   g_posicao_alvo geometry,
                                                   velocidade_a_perseguir real )
	RETURNS t_vector
	AS $$
	DECLARE
		novo_aceleracao_linear t_vector;
		alvo t_vector;
		perseguidor t_vector;
	BEGIN
		alvo := (ST_X(g_posicao_alvo), ST_Y(g_posicao_alvo))::t_vector;
		perseguidor := (ST_X(g_posicao_perseguidor), ST_Y(g_posicao_perseguidor))::t_vector;
		novo_aceleracao_linear := normalizar(alvo + (perseguidor * -1)) * velocidade_a_perseguir;
		RETURN novo_aceleracao_linear;
	END;
$$ LANGUAGE plpgsql;


-- Obter a nova aceleracao (linear e angular) do 'id_perseguidor' a perseguir 'id_alvo'
CREATE OR REPLACE FUNCTION obter_aceleracao_perseguidor( id_perseguidor int,
                                                         id_alvo int,
                                                         velocidade_a_perseguir real )
	RETURNS t_aceleracao
	AS $$
	SELECT novo_aceleracao_linear( c_perseguidor.g_posicao, c_alvo.g_posicao, $3 ), (c_perseguidor.aceleracao).angular
	FROM cinematica c_perseguidor, cinematica c_alvo
	WHERE c_perseguidor.id = $1 and c_alvo.id = $2;
$$ LANGUAGE 'sql';



-- 07
DROP TABLE IF EXISTS efeito_obj;
DROP TABLE IF EXISTS objecto_movel;´

-- Tabela com um qualquer objecto geometrico que se desloca com a cinematica
CREATE TABLE objecto_movel(
	id int primary key,
	nome varchar,
	id_cinematica int,
	norma_vel_max real, --velocidade max para o objeto
	boost real, --arranque (aceleracao) do objeto
	constraint fk1 FOREIGN KEY (id_cinematica) references cinematica(id)
);
SELECT AddGeometryColumn( '', 'objecto_movel', 'g_geo', 0, 'POLYGON', 2 );


-- efeito sobre o qual o terreno vai ter sobre o objeto
CREATE TABLE efeito_obj (
	id_objeto int,
	id_tipo_terreno varchar,
	efeito real,
	constraint pk_vel_obj primary key (id_objeto, id_tipo_terreno),
	constraint fk_id_objeto foreign key (id_objeto) references objecto_movel(id),
	constraint fk_id_tipo_terreno foreign key (id_tipo_terreno) references tipo_terreno(id_tipo_terreno)
);


