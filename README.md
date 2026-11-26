# Лабораторные работы № 1 и № 2. Вариант 1

## Цель
Настроить непрерывную интеграцию Java-приложения Task Manager в Jenkins и GitHub Actions, обеспечить проверку версий инструментов перед сборкой, выполнение тестов и публикацию артефактов.

## Подготовка
1. Распаковать архив и открыть каталог task-manager-cicd в IntelliJ IDEA как Maven-проект (pom.xml).
2. Установить JDK 21, Maven 3.10.0 (версия из методички), Git; добавить их bin в PATH и настроить JAVA_HOME. Проверить `java -version`, `mvn -version`, `git --version`.
3. В PowerShell из корня проекта выполнить `mvn -B -ntp clean verify`. Затем `mvn -B -ntp surefire-report:report-only`.
4. Создать пустой репозиторий GitHub. Выполнить команды (заменить URL своим):

```powershell
git init -b main
git add .
git commit -m "Complete CI labs variant 1"
git remote add origin https://github.com/YOUR-LOGIN/task-manager-cicd.git
git push -u origin main
git switch -c feature/task-priority
git push -u origin feature/task-priority
```

## ЛР № 1 — Jenkins
1. Открыть учебный Jenkins (в методичке http://localhost:8888). Установить Pipeline, Git, JUnit, Timestamper, если они отсутствуют.
2. Manage Jenkins → Nodes: создать или выбрать Windows-агент `windows-java21-agent`, метка `windows-java21-agent`, один executor, рабочий каталог (пример `G:\Jenkins\agent-win`); запустить агент по инструкции Jenkins. Проверить Online и доступность инструментов именно на агенте.
3. New Item → Pipeline → имя `Task-Manager-Priority-CI`. В Configure → Pipeline выбрать Pipeline script from SCM → Git → URL своего репозитория → ветка `*/feature/task-priority` → Script Path `Jenkinsfile`. Для закрытого репозитория выбрать credentials. Для автоматического запуска можно использовать Poll SCM с расписанием `H/5 * * * *`.
4. Save → Build Now. В Console Output проверить этапы Checkout, Check Java Version, Toolchain, Build and Verify, Generate Reports.
5. Вариант 1 реализован отдельным stage Check Java Version. Скрипт читает свойство java.specification.version; если оно не равно 21, бросает исключение. PowerShell завершается ненулевым кодом, bat сообщает Jenkins об ошибке и последующие этапы не выполняются. Сравнение основной версии допускает любые обновления JDK 21.
6. Открыть Test Result и Artifacts. Проверить XML Surefire/Failsafe, HTML-отчёты и JAR.
7. Негативный сценарий: на временной ветке изменить `-RequiredJava 21` на `-RequiredJava 17` в Jenkinsfile и запустить Pipeline с этой ветки на JDK 21. Ожидается FAILURE на Check Java Version и пропуск сборки. Вернуть 21, повторить запуск.

## ЛР № 2 — GitHub Actions
1. В репозитории открыть Actions → Java Application CI. Push в main/feature/**, PR в main или Run workflow запускают конвейер. Ручной запуск доступен после размещения workflow в основной ветке.
2. Job check-toolchain выполняется на windows-latest: checkout, установка Temurin 21, установка Maven требуемой версии с проверкой SHA-512, проверка Java и Maven.
3. Job verify зависит от check-toolchain через needs. Поскольку jobs работают на разных виртуальных машинах, он самостоятельно устанавливает инструменты и повторно проверяет версии. Maven-кэш подключён через setup-java.
4. Выполняется `mvn -B -ntp clean verify`. Отчёты загружаются даже при ошибке (если созданы); JAR — только при успехе. Срок хранения — 7 дней.
5. Негативный сценарий: временно поменять REQUIRED_JAVA с '21' на '17', не меняя установленный JDK. Ожидается failure в check-toolchain и skipped в verify. Вернуть значение и запустить заново. Для проверки Maven можно временно изменить аргумент RequiredMaven только в шаге проверки, оставив установку прежней.
6. Скачать `test-reports-windows` и `task-manager-jar` со страницы успешного запуска.

## Проверка REST API
После успешной сборки запустить `java -jar target/task-manager-cicd-1.0.0.jar`. В другом окне PowerShell:

```powershell
$t = Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/tasks -ContentType 'application/json' -Body '{"title":"CI test","priority":"HIGH"}'
Invoke-RestMethod -Uri 'http://localhost:8080/api/tasks?priority=HIGH'
Invoke-RestMethod -Method Patch -Uri "http://localhost:8080/api/tasks/$($t.id)/priority" -ContentType 'application/json' -Body '{"priority":"LOW"}'
```
Ожидается создание задачи с HIGH, присутствие в фильтре, затем изменение на LOW.

## Протокол испытаний (ожидаемые результаты, не фактический журнал)
| Сценарий | Ожидаемый результат | Фактический результат |
|---|---|---|
| Jenkins / Java 21 | Check Java Version успешен, сборка продолжается | Заполнить после запуска |
| Jenkins / ожидается Java 17, установлена 21 | FAILURE, сборка не запускается | Заполнить после запуска |
| GitHub / Java 21, Maven 3.10.0 | Оба Job успешны, два артефакта | Заполнить после запуска |
| GitHub / несовпадение Java или Maven | check-toolchain failure, verify skipped | Заполнить после запуска |
| Полный Maven verify | 14 модульных и 11 интеграционных тестов проходят | Не запускался |

## Результаты и вывод
Подготовлено 15 Java-файлов из предоставленного PDF, конфигурация Maven, Jenkinsfile, workflow и два PowerShell-скрипта. В исходниках 25 тестовых методов. XML и YAML проверены синтаксически; зависимость verify от check-toolchain подтверждена. На доступной машине команда Java показала java.specification.version = 21. Maven и PowerShell отсутствуют, доступа к учебному Jenkins и репозиторию нет; фактические статусы CI, тестовые отчёты, покрытие и JAR не получены. Версии зависимостей и Actions сохранены из методичек; доступность этих версий и URL дистрибутива Maven не подтверждена. Если учебная версия Maven недоступна, согласовать с преподавателем другую версию и изменить её одновременно в настройках проверки и установки. pom.xml восстановлен по требованиям методичек, добавлен httpclient5 для PATCH в интеграционных тестах. Необязательный Docker Job не включён.

Ранний контроль окружения предотвращает компиляцию и тестирование с неподходящими инструментами. Jenkins использует отдельный stage на Windows Agent, GitHub Actions — отдельный Job с зависимостью needs. Это повышает воспроизводимость сборки и упрощает диагностику.

## Что приложить к отчёту после выполнения
Ссылка на репозиторий; скриншоты успешного и отрицательного запуска Jenkins и Actions; Console Output и журналы jobs; результаты Surefire и Failsafe; HTML JaCoCo с реальными значениями покрытия; скачанные артефакты и результат запуска JAR. Не подставлять вымышленные результаты.
