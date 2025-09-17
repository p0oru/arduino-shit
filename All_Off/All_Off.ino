// All Off: turns off D2–D9 (bi-color LED pairs) and the built-in LED

const uint8_t LED_PAIRS[4][2] = {
  {2, 3}, {4, 5}, {6, 7}, {8, 9}
};

void setup() {
  for (uint8_t i = 0; i < 4; i++) {
    pinMode(LED_PAIRS[i][0], OUTPUT);
    pinMode(LED_PAIRS[i][1], OUTPUT);
    digitalWrite(LED_PAIRS[i][0], LOW);
    digitalWrite(LED_PAIRS[i][1], LOW);
  }
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
}

void loop() {}


