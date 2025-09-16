// Flash All LEDs
// Flashes all 8 bi-color LEDs (D2–D9) and the built-in LED repeatedly.
// Works with typical Nano robotics shields where each LED uses a pin pair:
// {2,3}, {4,5}, {6,7}, {8,9}

const uint8_t LED_PAIRS[4][2] = {
  {2, 3}, // LED1 pair
  {4, 5}, // LED2 pair
  {6, 7}, // LED3 pair
  {8, 9}  // LED4 pair
};

// If green/red look swapped, set to true.
const bool INVERT_GREEN = false;

void setOff(uint8_t idx) {
  digitalWrite(LED_PAIRS[idx][0], LOW);
  digitalWrite(LED_PAIRS[idx][1], LOW);
}

void setGreen(uint8_t idx) {
  const uint8_t a = LED_PAIRS[idx][0];
  const uint8_t b = LED_PAIRS[idx][1];
  if (INVERT_GREEN) {
    digitalWrite(a, LOW);
    digitalWrite(b, HIGH);
  } else {
    digitalWrite(a, HIGH);
    digitalWrite(b, LOW);
  }
}

void setRed(uint8_t idx) {
  const uint8_t a = LED_PAIRS[idx][0];
  const uint8_t b = LED_PAIRS[idx][1];
  if (INVERT_GREEN) {
    digitalWrite(a, HIGH);
    digitalWrite(b, LOW);
  } else {
    digitalWrite(a, LOW);
    digitalWrite(b, HIGH);
  }
}

void allOff() {
  for (uint8_t i = 0; i < 4; i++) setOff(i);
  digitalWrite(LED_BUILTIN, LOW);
}

void allGreen() {
  for (uint8_t i = 0; i < 4; i++) setGreen(i);
  digitalWrite(LED_BUILTIN, HIGH);
}

void allRed() {
  for (uint8_t i = 0; i < 4; i++) setRed(i);
  digitalWrite(LED_BUILTIN, HIGH);
}

void setup() {
  for (uint8_t i = 0; i < 4; i++) {
    pinMode(LED_PAIRS[i][0], OUTPUT);
    pinMode(LED_PAIRS[i][1], OUTPUT);
  }
  pinMode(LED_BUILTIN, OUTPUT);
  allOff();
}

void loop() {
  allGreen();
  delay(200);
  allOff();
  delay(120);
  allRed();
  delay(200);
  allOff();
  delay(120);
}


