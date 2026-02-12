# TODO

Refactor away the provided service class in favor of a combination of model methods and/or new single-purpose
service objects using the active_interaction library following the guidelines in @docs/service-objects.md.

For each of the methods in the class, determine if it should be moved to an appropriate model or if a new service object
should be created for it according to the guidelines

The existing methods should be left in place for now, but they should simply call the new method / service object (this is because I want to ensure that the tests continue to verify that they work).

## Guidelines

- Very short methods should be converted to methods on a model
- Methods where most of their logic operates on the model should be moved to the model
- Methods where most of the logic is active record calls should be moved to the model
- Very long methods should likely be converted to be a new service object
- Methods containing complex logic and/or involving multiple different models should be converted to a new service
  object.
