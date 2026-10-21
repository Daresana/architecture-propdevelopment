# PropDevelopment

Проектная работа пятого спринта.

| Задание | Решение |
| --- | --- |
| 1 | [Карта данных и рисков](Task1/data-security.drawio) |
| 2 | [Проверочный лист](Task2/checklist.md) |
| 3 | [Контекст](Task3/context.drawio), [контейнеры](Task3/containers.drawio), [требования](Task3/integration-requirements.md) |
| 4 | [Роли](Task4/roles.md), создание пользователей, ролей и привязок |
| 5 | [Сетевые политики](Task5/non-admin-api-allow.yaml) |

Для заданий 4 и 5 нужны Minikube, Docker, kubectl, Bash и OpenSSL. Команды выполняются из корня репозитория. Все изменения относятся к отдельному учебному кластеру `propdevelopment-sprint5`.

```bash
minikube start -p propdevelopment-sprint5 --driver=docker --cni=calico --cpus=2 --memory=3072 --keep-context
bash Task4/create-users.sh
bash Task4/create-roles.sh
bash Task4/bind-roles.sh
```

Сертификаты и отдельные kubeconfig пользователей сохраняются рядом с репозиторием в `.propdevelopment-users`. Срок сертификатов — одни сутки; закрытые ключи не входят в решение.

```bash
kubectl --kubeconfig ../.propdevelopment-users/sales-manager.config auth can-i get pods -n sales
kubectl --kubeconfig ../.propdevelopment-users/sales-manager.config auth can-i get secrets -n sales
kubectl --kubeconfig ../.propdevelopment-users/sales-manager.config auth can-i get pods -n housing
```

Ожидаемые ответы: `yes`, `no`, `no`. Полномочия остальных пользователей указаны в таблице ролей.

Для задания 5 развернуть четыре пода и одноимённые сервисы в `housing`:

```bash
kubectl --context propdevelopment-sprint5 -n housing run front-end-app --image=nginx:stable --labels=role=front-end --expose --port=80
kubectl --context propdevelopment-sprint5 -n housing run back-end-api-app --image=nginx:stable --labels=role=back-end-api --expose --port=80
kubectl --context propdevelopment-sprint5 -n housing run admin-front-end-app --image=nginx:stable --labels=role=admin-front-end --expose --port=80
kubectl --context propdevelopment-sprint5 -n housing run admin-back-end-api-app --image=nginx:stable --labels=role=admin-back-end-api --expose --port=80
kubectl --context propdevelopment-sprint5 -n housing wait --for=condition=Ready pod --all --timeout=120s
kubectl --context propdevelopment-sprint5 apply -f Task5/non-admin-api-allow.yaml
kubectl --context propdevelopment-sprint5 -n housing exec front-end-app -- curl -sS --max-time 3 http://back-end-api-app
kubectl --context propdevelopment-sprint5 -n housing exec front-end-app -- curl -sS --max-time 3 http://admin-back-end-api-app
```

Первый запрос должен вернуть страницу Nginx, второй — завершиться по тайм-ауту. Проверить также обратные направления и административную пару. Calico нужен для фактического применения NetworkPolicy.

Остановить стенд:

```bash
minikube stop -p propdevelopment-sprint5
```
