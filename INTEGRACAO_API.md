# Integração Strava Motos

## Configuração do Flutter
O app usa `lib/services/strava_api.dart`. Configure a URL da API e o UUID de um usuário já existente em `public.usuarios`. Para executar no terminal, dentro da pasta Flutter:

```bash
flutter pub get
flutter run --dart-define=STRAVA_API_URL=https://strava-motos-api-git-main-soaresmalcorrajoaovitor-1983.vercel.app --dart-define=STRAVA_USER_ID=COLOQUE_AQUI_O_UUID_REAL
```

O UUID pode ser copiado da coluna `usuarios.id` no Supabase. Não use e-mail no lugar do UUID. Sem essa configuração, o app mostra uma mensagem de configuração em vez de falhar silenciosamente.

## API
A pasta `Strava-Moto-Vercel` contém rotas alinhadas ao esquema informado: `motocicletas` usa `usuario_id`, `criado_em`; `viagens` usa `motocicleta_id`, `data_inicio`, `data_fim`, `criado_em`; dados do perfil são lidos de `usuarios`. Faça commit/push da pasta API para o repositório conectado à Vercel para publicar as novas rotas. Confirme que as variáveis `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` estão configuradas no projeto Vercel.

## Limitações conhecidas
A tela de garagem e a lista de viagens fazem CRUD com a API. O rastreamento ativo ainda é uma interface simulada: GPS em tempo real, criação automática de pontos em `pontos_gps` e persistência ao finalizar a viagem precisam de implementação separada com permissões de localização e teste em dispositivo.

## Segurança antes de produção
A API atual filtra por `usuario_id`, mas como ainda não há login no Flutter, esse ID é passado via `--dart-define`. Não disponibilize dados reais publicamente sem adicionar autenticação Supabase e validar o JWT no backend; não exponha a chave `service_role` no aplicativo.
