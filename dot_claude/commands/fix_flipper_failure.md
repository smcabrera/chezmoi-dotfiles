# Fix flipper failure

We have a number of specs now that are failing because of the way we mock the Features::CheckFlipperFeatureEnabled service object due to collisions of different rspec-mocks. The most common way to fix is to use the Flipper API directly instead of stubbing the service. We can make a replacement like this:

## Instructions
Ask the user which file they want to fix, offering the current file if there is one given.

Update the code according to the guidelines.

## Guidelines

### Old
```ruby
  mock_flipper_access(SOME_FEATURE)
  # this is equivalent
  mock_flipper_access(SOME_FEATURE, result: true)
```

### New
```ruby
  Flipper.enable(SOME_FEATURE)
```

We'll be disabling when the result is false like this

### Old
```ruby
mock_flipper_access(SOME_FEATURE, result: false)
```

```ruby
Flipper.disable(SOME_FEATURE)
```


Sometimes we are enabling or disabling a feature for a specific actor, we can convert that like this:

### Old
```ruby
  mock_flipper_access(SOME_FEATURE, actor: organization)
```

### New
```ruby
  Flipper.enable(SOME_FEATURE, organization)
```

Sometimes our use of mock_flipper_access attempts to assert that we use mixpanel directly. In these
cases we can just mock the MixpanelHelper class in the normal way. Example:

### Old
```ruby
# No need to mock MixpanelHelper when send_tracking is false
mock_flipper_access(SOME_FEATURE, send_tracking: true)
```

### New
```ruby
Flipper.enable(SOME_FEATURE, organization)
allow(MixpanelHelper).to receive(:track_event).and_return(true)
```

And then after the code in question is called we can assert that the event was tracked:

```ruby
expect(MixpanelHelper).to have_received(:track_event).with('some_event', { some: 'data' })
```

This won't always be necessary. If you run the test and it fails then you'll know that we never
really needed the assertion--the stub is sufficient.
