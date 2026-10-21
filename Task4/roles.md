# Роли Kubernetes

Четырём доменам соответствуют пространства имён `sales`, `housing`, `finance`, `data`. Сотрудники операционных команд просматривают состояние ресурсов своего домена. Инфраструктуру настраивают инженеры эксплуатации и DevOps. Доступ к секретам выделен специалисту ИБ.

| Роль | Права роли | Группы пользователей |
| --- | --- | --- |
| `domain-reader` — Role в каждом домене | `get`, `list`, `watch` для `pods`, `services`, `events`, `deployments`, `replicasets`, `jobs`, `cronjobs` только в своём namespace. Нет изменений, чтения Secret, запуска команд в подах и чтения журналов. | `sales-readers`, `housing-readers`, `finance-readers`, `data-readers` — операционные команды соответствующих доменов. |
| `cluster-configurator` — ClusterRole | `get`, `list`, `watch`, `patch`, `update` для `nodes`; `get`, `list`, `watch`, `create`, `patch`, `update` для `namespaces`; управление `networkpolicies` через `get`, `list`, `watch`, `create`, `update`, `patch`, `delete`. Нет управления RBAC, CSR, Secret и запуска подов. | `cluster-configurators` — инженеры эксплуатации и DevOps, которым поручена настройка кластера. |
| `secret-reader` — Role в каждом домене | `get`, `list` для `secrets` только в четырёх доменах. Нет изменения секретов и доступа к `kube-system`. | `security-readers` — специалист ИБ. |

Создаются четыре учебных пользователя:

| Пользователь | Группа | Проверка |
| --- | --- | --- |
| `sales-manager` | `sales-readers` | Просмотр в `sales`, отказ в других доменах и при чтении Secret. |
| `housing-manager` | `housing-readers` | Просмотр в `housing`, отказ в `sales` и при изменениях. |
| `platform-engineer` | `cluster-configurators` | Настройка сетевых политик и namespace, отказ в чтении Secret и изменении ролей. |
| `security-specialist` | `security-readers` | Просмотр Secret в четырёх доменах, отказ в изменении Secret и чтении Secret в `kube-system`. |

Пользователи аутентифицируются клиентскими сертификатами. В сертификате `CN` задаёт имя пользователя, `O` — группу. RoleBinding связывает группу с Role, ClusterRoleBinding — группу с ClusterRole. Права бизнес-приложений и доступ к строкам БД этой настройкой не задаются.
