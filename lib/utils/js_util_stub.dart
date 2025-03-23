// Stub file for dart:js when compiling for non-web platforms

// Define a minimal stub version of the context property
class JsContext {
  // Define a safe implementation that returns null for any property access
  dynamic operator [](String key) => null;

  // Define a no-op implementation for callMethod
  dynamic callMethod(String method, [List<dynamic>? args]) => null;
}

// Create a static instance of the context
final JsContext context = JsContext();

// Define any other stubs needed for API compatibility
class JsObject {
  dynamic operator [](String key) => null;
}

// Additional stub types if needed
class JsFunction {}

class JsArray {}

// Define minimal stub versions of the classes and methods needed
class JSObject {}

class JSAny {}

// Empty class definition for JS annotation - won't be used in non-web
class JS {
  final String name;
  const JS(this.name);
}
