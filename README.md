# PKCE-supporting OAuth Proxy Service

This small Sinatra app is a proof of concept OAuth service that proxies to a third-party OAuth provider using the authorization code grant web application flow, but extending it to support [PKCE](https://tools.ietf.org/html/rfc7636#section-4.1) for public clients for services that do not currently support it.

Warning: this is not currently a production-ready service but could be used as the basis for one.

## The problem

In the normal OAuth web application flow, a confidential client can obtain an access token by:

1. Directing the user to an OAuth endpoint for a service, passing along a `client_id` and a `redirect_uri`
2. The user authenticates and authorises the client and the service redirects to the redirect_uri, passing along a `code` parameter.
3. The client makes a second `POST` request to the service's access token endpoint, passing along the `client_id`, `client_secret` and the `code` obtained in the previous step.
4. The service verifies the client ID and secret and returns an `access_token` (and perhaps a `refresh_token`) in response.

This flow works fine for confidential clients, like web servers, as they can keep the client secret secure. It is essential that the client secret is kept secret as it is used (sometimes along with a registered redirect URI) to prevent man-in-the-middle attacks by verifying that the client requesting the access token is the same client that originally requested the authorization code.

By definition, native apps (mobile, desktop etc.) and client-side web apps are considered "public" clients. It is impossible for these clients to use a `client_secret` without exposing it (e.g. client-side Javascript web apps will expose the secret in their source in the browser, similarly embedded strings within native app code can be easily extracted).

## The solution

As well as taking steps such as checking redirect URIs against pre-registered values, the OAuth 2 spec recommends the use of "Proof Key for Code Exchange", however not all OAuth providers currently support this. In this model, clients do not require a `client_secret`. Instead, they they generate their own high-entropy random `code_verifier` every time they require an authorization code. The flow when using PKCE is:

1. The client generates a `code_verifier` and a hashed and encoded `code_challenge` derived from the `code_verifier` using SHA256 and Base64 URL encoding.
2. The client directs the user to the OAuth endpoint as before, but also passes the `code_challenge`.
3. The user authenticates and is redirected back to the `redirect_uri` with the authorization code - the server keeps a record of this code along with the original `code_challenge`.
4. The client makes a second `POST` request to obtain an access token, this time sending the original `code_verifier` instead of a `client_secret`.
5. The service verifies the `code_verifier` by hashing and encoding it and comparing it with the original `code_challenge` for the given `code`.
6. If the `code_verifier` is correct, it returns an `access_token`.

Unfortunately, not all services support PKCE, which often leaves implementations of a public client with two options:

1. Embed the `client_secret` in their application source or,
2. Implement their own hosted service that their client can obtain the access token from, which acts as a proxy to the original OAuth endpoint and attaches the client secret to each request.

The second option seems like a reasonable solution but it's still not ideal on it's own. Whilst it doesn't expose your `client_secret`, having a web service that simply forwards on any requests for an access token with the `client_secret` attached means you're effectively giving an attacker access to your `client_secret` even though they don't know it's actual value.

This proof of concept aims to solve this problem by effectively acting like a PKCE-supporting OAuth service in it's own right, which can be configured to proxy to a specific OAuth endpoint. To do this, it simply requires knowledge of the authorize and access_token endpoints for the target OAuth service as well as the client secret. It then:

1. Requires clients make a request to it's own `/oauth/authorize` endpoint, passing along all the parameters it would have sent to the original endpoint but also including a `code_challenge`.
2. The proxy stores a reference to the `code_challenge` and the original `redirect_uri` in it's session before redirecting the user to the original endpoint with a new `redirect_uri` pointing back to itself.
3. When the original service redirects back to the proxy server with it's `code`', the server persists the `code_challenge` (currently stored in it's session) to a key-value store, keyed against the `code`, before redirecting to the original `redirect_uri` for the public client with the `code`.
4. The client makes a `POST` request to the proxy server to obtain an `access_token`, along with the original `code_verifier`.
5. The proxy server uses the `code` in the access token request to lookup the original `code_challenge` from the key-value store and compares it against the `code_verifier`. If they match, it forwards the request on to the original access token endpoint along with the `client_secret` and returns the response as-is to the client.
