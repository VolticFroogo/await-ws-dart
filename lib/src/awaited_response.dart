class AwaitedResponse {
  dynamic message;
  Error error;

  AwaitedResponse(dynamic message, Error error) {
    this.message = message;
    this.error = error;
  }
}
