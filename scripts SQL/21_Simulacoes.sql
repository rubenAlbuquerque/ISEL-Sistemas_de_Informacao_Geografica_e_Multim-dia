---------------------------------------
-- Simular tragetorias
---------------------------------------


-- norma_vel_max: velocidade max para o objeto
-- boost: arranque (aceleracao) do objeto
-- efeito: efeito sobre o qual o terreno vai ter sobre o objeto
-- t_velocidade: (linear t_vector, angular real)
-- t_aceleracao: (linear t_vector, angular real)
-- t_vector : (x real, y real)
-- norma (vec t_vector): return sqrt(power(vec.x, 2) + power(vec.y, 2));



do $$
begin
	for i in 1..100 loop

		-- Inserir os dados da table cinematica na table cinematica_hist
		INSERT INTO cinematica_hist
		SELECT nextval('cinematica_hist_id_hist_seq'), id, orientacao, velocidade , aceleracao, g_posicao
		FROM cinematica;


		--o código está atualizando a coluna velocidade na tabela cinematica com base em várias 
		-- condições e cálculos complexos envolvendo várias tabelas e funções
		-- (Atualização da Velocidade na Tabela cinematica)

		UPDATE cinematica
		SET velocidade =
			CASE WHEN norma((c.velocidade).linear) > o.norma_vel_max * e.efeito
				--Se a norma da componente linear da "velocidade atual" (c.velocidade) 
				-- for maior que um limite (o.norma_vel_max * e.efeito), logo o objeto sofre um efeito de travagem
				THEN novo_velocidade( c.velocidade, -- t_velocidade,
									((normalizar((c.velocidade).linear) * -1) * o.boost * (1 - e.efeito)::real, 
									 (c.aceleracao).angular), -- (t_vector, aceleracao angular)
									1 ) -- tempo real
			ELSE
				CASE WHEN norma((novo_velocidade( c.velocidade, -- t_velocidade
												  ((c.aceleracao).linear * e.efeito, 
												   (c.aceleracao).angular), 
												1 ) -- tempo real
								).linear) > o.norma_vel_max * e.efeito
					-- Se a norma da componente linear da "nova velocidade" (novo_velocidade) 
					-- for maior que um limite (o.norma_vel_max * e.efeito)
					
					THEN (
						-- novo_resultado_velocidade: ajuste de velocidade
						--aceleracao := normalizar( alvo.g_posicao – perseguidor.g_posicao ) * boost ??
						normalizar(
									(novo_velocidade( c.velocidade, --t_velocidade, 
													((c.aceleracao).linear * e.efeito, (c.aceleracao).angular), -- t_aceleracao, 
													1 ) -- tempo real
									).linear
						) * o.norma_vel_max * e.efeito * 0.9, -- 90% da velocidade maxima? nova velocidade linear? 
						(novo_velocidade( c.velocidade, 
										((c.aceleracao).linear * e.efeito, (c.aceleracao).angular), 
										1 )
						).angular -- mantem a velocidade angular? nova velocidade angular?
					)::t_velocidade -- return (velocidade linear, velocidade angular)
				ELSE
					-- Se a norma da componente linear da "nova velocidade" (novo_velocidade)
					-- for menor que um limite (o.norma_vel_max * e.efeito)
					novo_velocidade( c.velocidade, 
									((c.aceleracao).linear * e.efeito, (c.aceleracao).angular), 
									1 )
				END
			END
		FROM cinematica c, objecto_movel o, efeito_obj e, terrenos_rios t, (
			SELECT c.id as id, max(t.nivel) as nivel
			FROM cinematica c, terrenos_rios t
			WHERE ST_Within(c.g_posicao, t.g_geo) -- se a posicao do objeto estiver dentro do terreno?
			GROUP BY c.id
		) as n -- nivel do terreno?
		WHERE
			n.id = c.id AND
			c.id = o.id_cinematica AND
			o.id = e.id_objeto AND
			ST_Within(c.g_posicao, t.g_geo) AND	
			t.id_tipo_terreno = e.id_tipo_terreno AND
			n.nivel = t.nivel AND
			cinematica.id = c.id
		;

		-- Atualizar a coluna g_posicao da tabela cinematica com base na coluna velocidade
		-- (Atualização da Posição e Orientação na Tabela cinematica)
		UPDATE cinematica
		SET g_posicao = novo_posicao( g_posicao, velocidade, 1 );

		-- Atualizar a coluna orientacao da tabela cinematica com base na coluna velocidade
		UPDATE cinematica
		SET orientacao = novo_orientacao( orientacao, velocidade, 1 );

		-- Atualizar a coluna g_geo da tabela objecto_movel com base na coluna g_posicao da tabela cinematica
		-- (Atualização da Geometria na Tabela objecto_movel)
		UPDATE objecto_movel
		SET g_geo = ST_Translate(o.g_geo, ST_X(c.g_posicao) - ST_X(ST_Centroid(o.g_geo)), 
								 ST_Y(c.g_posicao) - ST_Y(ST_Centroid(o.g_geo))) -- ST_Translate(geometry g1, float x, float y)
		FROM objecto_movel o, cinematica c
		WHERE o.id = c.id AND objecto_movel.id = o.id
		;

	end loop;
end; $$







---------------------------------------
-- Simular perseguicao
---------------------------------------
--




do $$
begin
	for i in 1..100 loop

		INSERT INTO cinematica_hist
		SELECT nextval('cinematica_hist_id_hist_seq'), id, orientacao, velocidade , aceleracao, g_posicao
		FROM cinematica;

		-- atualizar a aceleracao na tabela cinematica
		UPDATE cinematica
		SET aceleracao = obter_aceleracao_perseguidor( pp.id_perseguidor, pp.id_alvo, o.boost )
		FROM pp, objecto_movel o
		WHERE cinematica.id = pp.id_perseguidor and o.id_cinematica = pp.id_perseguidor
		;


		UPDATE cinematica
		SET velocidade =
		CASE WHEN norma((c.velocidade).linear) > o.norma_vel_max * e.efeito
			THEN novo_velocidade( c.velocidade, ((normalizar((c.velocidade).linear) * -1) * o.boost * (1 - e.efeito)::real, (c.aceleracao).angular), 1 )
		ELSE
			CASE WHEN norma((novo_velocidade( c.velocidade, ((c.aceleracao).linear * e.efeito, (c.aceleracao).angular), 1 )).linear) > o.norma_vel_max * e.efeito
			THEN (
				normalizar((novo_velocidade( c.velocidade, ((c.aceleracao).linear * e.efeito, (c.aceleracao).angular), 1 )).linear) * o.norma_vel_max * e.efeito * 0.9,
				(novo_velocidade( c.velocidade, ((c.aceleracao).linear * e.efeito, (c.aceleracao).angular), 1 )).angular
			)::t_velocidade
			ELSE novo_velocidade( c.velocidade, ((c.aceleracao).linear * e.efeito, (c.aceleracao).angular), 1 )
			END
		END
		FROM cinematica c, objecto_movel o, efeito_obj e, terrenos_rios t, (
			SELECT c.id as id, max(t.nivel) as nivel
			FROM cinematica c, terrenos_rios t
			WHERE ST_Within(c.g_posicao, t.g_geo)
			GROUP BY c.id
		) as n
		WHERE
			n.id = c.id AND
			c.id = o.id_cinematica AND
			o.id = e.id_objeto AND
			ST_Within(c.g_posicao, t.g_geo) AND	
			t.id_tipo_terreno = e.id_tipo_terreno AND
			n.nivel = t.nivel AND
			cinematica.id = c.id
		;


		UPDATE cinematica
		SET g_posicao = novo_posicao( g_posicao, velocidade, 1 );


		UPDATE cinematica
		SET orientacao = novo_orientacao( orientacao, velocidade, 1 );


		UPDATE objecto_movel
		SET g_geo = ST_Translate(o.g_geo, ST_X(c.g_posicao) - ST_X(ST_Centroid(o.g_geo)), ST_Y(c.g_posicao) - ST_Y(ST_Centroid(o.g_geo)))
		FROM objecto_movel o, cinematica c
		WHERE o.id = c.id AND objecto_movel.id = o.id
		;

	end loop;
end; $$














