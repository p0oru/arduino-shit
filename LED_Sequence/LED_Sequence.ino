// Robokidz LED Test (LED1–LED8 on D2–D9)
// Turns all LEDs on, then turns them off one by one, and repeats.

const uint8_t LED_PINS[] = {2, 3, 4, 5, 6, 7, 8, 9};
const uint8_t NUM_LEDS = sizeof(LED_PINS) / sizeof(LED_PINS[0]);

// If your shield's LEDs are inverted, swap these to: ON = LOW; OFF = HIGH;
const uint8_t ON = HIGH;
const uint8_t OFF = LOW;

void setup() {
  for (uint8_t i = 0; i < NUM_LEDS; i++) {
    pinMode(LED_PINS[i], OUTPUT);
    digitalWrite(LED_PINS[i], OFF);
  }
}

void loop() {
  // Turn all LEDs on
  for (uint8_t i = 0; i < NUM_LEDS; i++) {
    digitalWrite(LED_PINS[i], ON);
  }
  delay(800);

  // Turn them off one by one
  for (uint8_t i = 0; i < NUM_LEDS; i++) {
    digitalWrite(LED_PINS[i], OFF);
    delay(200);
  }

  delay(400);
}




