# Checklist de requisitos - Strava Motos

Fonte: `Requisitos Funcionais e Não Funcionais.pdf`, versão 1.0. Este checklist registra o estado do código disponível nesta cópia do projeto. Itens que dependem de publicação, execução em Android ou credenciais de serviços externos não são considerados concluídos apenas por existirem no código.

## Requisitos funcionais

| ID | Requisito resumido | Estado | Evidência / próxima ação |
|---|---|---|---|
| RF01 | Persistir dados necessários no dispositivo conforme as funções disponíveis | Parcial | Dados principais ficam no Supabase; viagens marcadas para offline também são guardadas localmente por conta. Motos/perfil e viagens comuns ainda não têm cache local completo. |
| RF02 | Entrar com conta Google | Parcial | OAuth web funciona; deep link `com.example.stravamotos://login-callback/` registrado no Android/iOS e usado pelo app. Adicionar URL à allowlist do Supabase e validar o retorno OAuth nos aparelhos. |
| RF03 | Iniciar, pausar, retomar e finalizar viagem | Parcial | Fluxo e GPS em primeiro plano estão no app; requer publicar API/migration e validar no telefone. |
| RF04 | Cadastrar uma ou mais motos com modelo, cilindrada e consumo | Parcial | Modelo, cilindrada, placa, ano, cor e tanque têm CRUD e validação; consumo km/L foi restringido ao Premium. Aplicar migration de detalhes da moto e publicar API. |
| RF05 | Registrar localização por GPS durante o percurso | Parcial | Coleta em primeiro plano implementada; teste Android e migration `pontos_gps` pendentes. |
| RF06 | Detectar períodos em movimento e parado | Parcial | Estimativa por velocidade GPS (limiar de 3 km/h) adicionada; calibrar em teste real. |
| RF07 | Exibir localização em tempo real no mapa | Parcial | Ao abrir a configuração da viagem o app solicita localização, centraliza no aparelho e mostra ponto azul com halo de precisão; fixes acima de 35 m são ignorados no marcador e métricas. Validar em Android físico. |
| RF08 | Continuar rastreando com app minimizado ou tela bloqueada | Parcial | Serviço de localização Android em primeiro plano, notificação persistente e permissão "Permitir o tempo todo" configurados; validar em aparelho. O app não recupera uma sessão após o Android encerrar o processo. |
| RF09 | Exibir mapa do percurso depois de finalizar | Parcial | Detalhes agora desenham os pontos salvos; depende da migration e publicação da API. |
| RF10 | Calcular e mostrar distância | Parcial | Soma de segmentos GPS implementada; validar precisão com celular. |
| RF11 | Mostrar duração total, em movimento e parado | Parcial | Duração ativa e estimativa por amostras GPS implementadas; validar pausas, paradas longas e gaps do sinal. |
| RF12 | Calcular velocidade média | Parcial | Distância dividida pela duração ativa; validar no Android. |
| RF13 | Mostrar velocidade máxima | Parcial | Maior velocidade calculada dos segmentos GPS; validar e calibrar no Android. |
| RF14 | Consultar histórico de viagens | Implementado | Histórico carregado pela API, com edição e exclusão. |
| RF15 | Ver detalhe com mapa, distância, duração e velocidades | Parcial | Tela de detalhes e mapa implementados; viagens antigas sem pontos mostram estado vazio. |
| RF16 | Excluir atividades | Implementado | Exclusão de viagens pela API autenticada. |
| RF17 | Editar motos | Implementado | Formulário e atualização existentes. |
| RF18 | Contratar plano Premium | Parcial | Bloqueios Free/Premium e entitlement de teste com e-mail autorizado implementados; cobrança e confirmação de pagamento ainda precisam de RevenueCat/lojas. |
| RF19 | Usuário Premium baixar e salvar corridas offline | Parcial | Salva localmente a viagem e pontos GPS por conta, acessível sem rede e restrito a Premium para novos downloads. Não baixa tiles/mapa base; billing ainda não é comprovado por loja. |
| RF20 | Abrir corridas já salvas offline, com bloqueio para novas cópias no plano gratuito | Parcial | Histórico cai para as rotas salvas localmente sem conexão e abre um traçado offline. O mapa de ruas/tiles não é baixado; a validação de assinatura ainda depende do provedor. |
| RF21 | Restringir funções Premium a assinaturas ativas | Parcial | API bloqueia gravação/consulta de consumo e estimativa para contas Free; offline também é limitado no app. A ativação é administrativa via banco até integrar provedor de cobrança. |

## Requisitos não funcionais

| ID | Requisito resumido | Estado | Evidência / próxima ação |
|---|---|---|---|
| RNF01 | Atualização GPS sem atraso significativo | Parcial | Stream configurado para alta precisão e filtro de 5 m; medir em aparelho real. |
| RNF02 | Disponibilidade quando dispositivo e serviços estiverem disponíveis | Parcial | App depende de Supabase, API Vercel e tiles OSM; validar erros/reconexão. |
| RNF03 | Privacidade de dados pessoais e de localização | Parcial | API deriva o perfil do token e filtra registros por usuário; publicar e revisar políticas do banco. |
| RNF04 | Autenticação e armazenamento seguros | Parcial | OAuth e token Bearer implementados; manter chave secreta somente na Vercel e validar Android. |
| RNF05 | Fluxo simples e intuitivo | Parcial | Início, rotas, garagem, perfil e detalhes receberam hierarquia visual e ações mais claras; falta revisão visual no telefone. |
| RNF06 | Compatibilidade com Android usando Flutter | Parcial | Projeto Flutter e permissões Android presentes; falta executar em Android Studio/telefone. Também há arquivos iOS, mas ainda não houve build em Xcode. |
| RNF07 | Usar a melhor precisão disponível no aparelho | Parcial | `bestForNavigation` e filtro de precisão aplicados; conferir comportamento em GPS real. |
| RNF08 | Arquitetura organizada e modular | Parcial | App e API separados; serviço de rastreamento ainda deve sair da tela para módulo próprio. |
| RNF09 | Integridade e isolamento dos dados | Parcial | Rotas e motos são associadas ao perfil autenticado; aplicar migrations e revisar todas as policies. |
| RNF10 | Reduzir consumo de bateria e recursos | Parcial | Coleta usa filtro de distância e não habilita wake lock; medir bateria em aparelho, inclusive com tela bloqueada. |
| RNF11 | Manter registro em segundo plano no Android | Parcial | Serviço foreground e notificação configurados com Geolocator; conceder permissão "Permitir o tempo todo" e validar em Android. |
| RNF12 | Funcionar offline após disponibilizar dados | Parcial | Rotas explicitamente salvas podem ser abertas sem rede, com traçado GPS; mapa de ruas, perfil, motos e rotas não baixadas dependem de conexão. |

## Próximos passos recomendados

### Recursos adicionais solicitados

| Recurso | Estado | Evidência / próxima ação |
|---|---|---|
| Nome do perfil vindo do Google | Implementado no app; sincronização do banco depende do deploy da API | O app usa `full_name`/`name` dos metadados Google quando o nome salvo ainda é o placeholder. A API atualiza `usuarios.nome` ao carregar o perfil. |
| Modo escuro | Implementado | Alternância no Perfil; preferência persistida localmente no dispositivo. |
| GPS ao entrar em Configurar viagem | Implementado; teste físico pendente | Solicita a permissão em primeiro plano ao abrir a tela e centra o mapa em uma posição atual do aparelho, com marcador e círculo de precisão. Fixes imprecisos são filtrados de 50 m para 35 m e há filtro de ruído nas métricas; verificar em movimento/parado no aparelho. |
| Dados adicionais da moto | Implementado no app/API; migration pendente | Placa (padrão antigo/Mercosul), ano, cor e capacidade do tanque são opcionais e validados nos dois lados. |
| Cadastro de viagens (POST) | Implementado no app/API; smoke test autenticado pendente | POST `/api/viagens` grava métricas, datas, moto e pontos GPS; valida moto, datas e pontos. Confirmar com usuário autenticado após publicar a API. |
| Consumo médio e combustível Premium | Implementado no app/API; billing pendente | Litros estimados = distância em km ÷ consumo km/L cadastrado na moto; validação Free/Premium no servidor. Requer migration `202611060003_fuel_estimate.sql` e perfil `premium=true`. |
| Estimativa de combustível por viagem | Implementado no app/API; migração anterior pendente | Ao salvar, calcula distância ÷ consumo km/L cadastrado na moto, confirma e mostra no detalhe para Premium. É uma estimativa, não leitura do combustível real. |

1. Aplicar no Supabase as migrations `202611060001_auth_user_mapping.sql`, `202611060002_track_points.sql`, `202611060003_fuel_estimate.sql` e `202611110001_motorcycle_details.sql`.
2. Adicionar `com.example.stravamotos://login-callback/` à lista de Redirect URLs do Supabase Auth.
3. Publicar na Vercel a versão atualizada da API, incluindo validação de motos/viagens e bloqueio Premium no servidor.
4. Validar no Android o login, rastreamento, pausa/parada, notificação, permissão Always e mapa; depois tratar recuperação caso o sistema encerre o processo.
5. Definir e integrar cobrança (Google Play/App Store) com entitlement verificado no servidor; hoje o app só lê `usuarios.premium`.
6. Se o requisito pedir ruas e lugares sem rede, escolher provedor de tiles com licença e cache offline; a cópia atual salva os pontos e mostra o traçado sem o mapa base.
7. Para instalar em iPhone, preparar assinatura iOS e fazer build/distribuição em macOS com Xcode; trocar o Bundle ID genérico `com.example.stravaMotos` por um identificador exclusivo antes de publicar.
