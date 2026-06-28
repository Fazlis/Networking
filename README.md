# Networking — руководство по использованию

Лёгкий протокол-ориентированный сетевой слой для iOS. Состоит из двух модулей:

| Модуль | Что внутри | От чего зависит |
|---|---|---|
| **NetworkProtocols** | Все протоколы-контракты (`Endpoint`, `HTTPMethod`, `CacheProtocol`, `RequestModifier` и т.д.) | Ничего |
| **Networking** | Конкретная реализация — `HTTPClient` | `NetworkProtocols` |

Идея простая: ты описываешь запрос декларативно (через `Endpoint`), а `HTTPClient` собирает `URLRequest` и выполняет его. Сборку запроса и его выполнение пакет **не реализует за тебя** — это два протокола (`RequestBuilderProtocol` и `RequestExecutorProtocol`), которые нужно реализовать самому (или взять готовую реализацию, если она будет добавлена позже). Ниже — пример минимальной реализации, чтобы всё сразу заработало.

```
Endpoint ──► RequestBuilder ──► URLRequest ──► RequestExecutor ──► Data
   │                                                  │
   └─ requestModifiers (заголовки, токены...)         └─ URLSession.data(for:)
```

## Установка (Swift Package Manager)

```swift
// Package.swift
dependencies: [
    .package(path: "../Networking") // или url: "...", from: "1.0.0"
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "Networking", package: "Networking")
        ]
    )
]
```

`NetworkProtocols` подтянется автоматически — `Networking` зависит от него.

---

## 1. `HTTPMethod`

Обычный enum, ничего особенного:

```swift
public enum HTTPMethod: String {
    case get, post, put, patch, delete
}
```

## 2. `Endpoint` — описание запроса

Это центральный протокол. Один `Endpoint` = один конкретный запрос (например "получить профиль пользователя").

```swift
public protocol Endpoint {
    associatedtype CachePolicy: CacheProtocol

    var id: String { get }                    // есть значение по умолчанию
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var cachePolicy: CachePolicy { get }
    var timeoutInterval: TimeInterval { get }  // по умолчанию 30 сек
    var requestModifiers: [RequestModifier] { get } // по умолчанию []
}
```

Свойства `id`, `timeoutInterval`, `requestModifiers` можно не указывать — для них уже есть реализация по умолчанию.

**Пример своего эндпоинта:**

```swift
struct GetUserEndpoint: Endpoint {
    typealias CachePolicy = NoCachePolicy

    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/users/me" }
    var method: HTTPMethod { .get }
    var cachePolicy: NoCachePolicy { NoCachePolicy() }
}
```

## 3. Кэш-политика (`CacheProtocol`)

Это пока **только контракт**, без реальной логики кэширования внутри пакета — сам пакет не читает и не пишет в кэш. `cachePolicy` просто навешивается на `Endpoint` как метаданные, а использовать их (или игнорировать) должны твои реализации `RequestBuilder`/`RequestExecutor`.

```swift
public protocol CacheLevel: Sendable {}

public protocol MemoryCacheProtocol: Sendable {
    associatedtype Level: CacheLevel
    var timeToLive: TimeInterval? { get }
    var level: Level { get }
}

public protocol CacheProtocol: Sendable {
    associatedtype CacheLevel: MemoryCacheProtocol
    var useCache: Bool { get }
    var cacheLevel: CacheLevel { get }
}
```

Если кэш пока не нужен — заведи "пустую" политику и используй её везде:

```swift
struct NoCacheLevel: CacheLevel {}

struct NoCache: MemoryCacheProtocol {
    var timeToLive: TimeInterval? { nil }
    var level: NoCacheLevel { NoCacheLevel() }
}

struct NoCachePolicy: CacheProtocol {
    var useCache: Bool { false }
    var cacheLevel: NoCache { NoCache() }
}
```

## 4. `RequestModifier` — модификация запроса перед отправкой

Удобно для авторизационных заголовков, трассировки, и т.п. Применяются по очереди в том порядке, в котором перечислены в `requestModifiers`.

```swift
public protocol RequestModifier: Sendable {
    func modify(_ request: inout URLRequest) async throws
}
```

```swift
struct AuthModifier: RequestModifier {
    let token: String

    func modify(_ request: inout URLRequest) async throws {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}
```

Подключается так:

```swift
struct GetUserEndpoint: Endpoint {
    typealias CachePolicy = NoCachePolicy

    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/users/me" }
    var method: HTTPMethod { .get }
    var cachePolicy: NoCachePolicy { NoCachePolicy() }
    var requestModifiers: [RequestModifier] { [AuthModifier(token: "abc123")] }
}
```

## 5. `RequestBuilderProtocol` — твоя реализация

Превращает `Endpoint` в `URLRequest`. Пакет **не содержит** готовой реализации — пиши свою:

```swift
public protocol RequestBuilderProtocol {
    func build<E: Endpoint>(from endpoint: E) async throws -> URLRequest
}
```

```swift
struct DefaultRequestBuilder: RequestBuilderProtocol {
    func build<E: Endpoint>(from endpoint: E) async throws -> URLRequest {
        let url = endpoint.baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url, timeoutInterval: endpoint.timeoutInterval)
        request.httpMethod = endpoint.method.rawValue

        for modifier in endpoint.requestModifiers {
            try await modifier.modify(&request)
        }

        return request
    }
}
```

## 6. `RequestExecutorProtocol` — твоя реализация

Отвечает за фактическую отправку запроса (через `URLSession` или мок в тестах). Тоже без готовой реализации в пакете:

```swift
public protocol RequestExecutorProtocol {
    func execute(_ request: URLRequest) async throws -> Data
}
```

```swift
struct URLSessionExecutor: RequestExecutorProtocol {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func execute(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return data
    }
}
```

## 7. `HTTPClient` — собираем всё вместе

```swift
public struct HTTPClient: HTTPClientProtocol {
    public init(
        session: URLSession = .shared,
        requestBuilder: RequestBuilderProtocol,
        requestExecutor: RequestExecutorProtocol
    )

    public func send<E: Endpoint>(_ endpoint: E) async throws -> Data
}
```

```swift
let client = HTTPClient(
    requestBuilder: DefaultRequestBuilder(),
    requestExecutor: URLSessionExecutor()
)

let data = try await client.send(GetUserEndpoint())
let user = try JSONDecoder().decode(User.self, from: data)
```

> ⚠️ **На что обратить внимание:** параметр `session` в `init` у `HTTPClient` сейчас никуда не сохраняется и не используется внутри `send` — он "мёртвый". Реальная `URLSession` должна передаваться в твою реализацию `RequestExecutorProtocol` (как в примере выше), а не ожидаться от `HTTPClient`.

---

## Полный пример с нуля

```swift
import Networking
import NetworkProtocols

// 1. Кэш-политика (если не нужна — пустышка)
struct NoCacheLevel: CacheLevel {}
struct NoCache: MemoryCacheProtocol {
    var timeToLive: TimeInterval? { nil }
    var level: NoCacheLevel { NoCacheLevel() }
}
struct NoCachePolicy: CacheProtocol {
    var useCache: Bool { false }
    var cacheLevel: NoCache { NoCache() }
}

// 2. Эндпоинт
struct GetUserEndpoint: Endpoint {
    typealias CachePolicy = NoCachePolicy

    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String { "/users/me" }
    var method: HTTPMethod { .get }
    var cachePolicy: NoCachePolicy { NoCachePolicy() }
    var requestModifiers: [RequestModifier] { [AuthModifier(token: "abc123")] }
}

// 3. Модификатор запроса
struct AuthModifier: RequestModifier {
    let token: String
    func modify(_ request: inout URLRequest) async throws {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

// 4. Сборщик запроса
struct DefaultRequestBuilder: RequestBuilderProtocol {
    func build<E: Endpoint>(from endpoint: E) async throws -> URLRequest {
        let url = endpoint.baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url, timeoutInterval: endpoint.timeoutInterval)
        request.httpMethod = endpoint.method.rawValue
        for modifier in endpoint.requestModifiers {
            try await modifier.modify(&request)
        }
        return request
    }
}

// 5. Исполнитель запроса
struct URLSessionExecutor: RequestExecutorProtocol {
    let session: URLSession = .shared
    func execute(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}

// 6. Использование
let client = HTTPClient(
    requestBuilder: DefaultRequestBuilder(),
    requestExecutor: URLSessionExecutor()
)

let data = try await client.send(GetUserEndpoint())
let user = try JSONDecoder().decode(User.self, from: data)
```

---

## Частые вопросы

**Зачем нужны два модуля, а не один?**
`NetworkProtocols` без зависимостей — его можно подключить туда, где нужны только контракты (например, в моки для unit-тестов), не таская за собой `Networking`.

**Как добавить настоящее кэширование?**
Сейчас `cachePolicy` — это просто метаданные на `Endpoint`. Логику чтения/записи в кэш нужно реализовать самому внутри своих `RequestBuilder`/`RequestExecutor` (например, проверять `endpoint.cachePolicy.useCache` перед походом в сеть).

**Как замокать сеть в тестах?**
Реализуй `RequestExecutorProtocol` с фейковым `execute`, который возвращает заранее заданные `Data` без реального похода в сеть — `HTTPClient` про это ничего не знает, ему всё равно, что у него внутри.
