# inspr

Inspr ~ Inspirational Quotes

## Getting Started

This project has 1.7k+ free inspirational quotes.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Run app in development

`flutter run --flavor dev`

## Build for production

## `flutter build appbundle --flavor prod`

---

# api

## Getting Started

- Run `cd api/` to navigate to folder
- Run `npm install` to install the dependencies
- Run `node app` or `nodemon app` to launch on your local server
- Test with GET request to `{url}:{port}/api/quotes`

## API status codes

Ignore these, implement your own

- 0 => Request unsuccessful
- 1 => Request successful
- 2 => Validation error
- 3 => Authentication is required/invalid
- 4 => Application error
- 5 => Not found
- 6 => Account not verified

## References

- https://www.restapitutorial.com/httpstatuscodes.html
- https://www.npmjs.com/package/validator
- https://generate-random.org/api-key-generator
