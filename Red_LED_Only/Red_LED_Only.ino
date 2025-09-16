// Red LED Only
// Lights only the red sides of the 4 bi-color LEDs (pairs on D2–D9) continuously.

const uint8_t LED_PAIRS[4][2] = {
  {2, 3},
  {4, 5},
  {6, 7},
  {8, 9}
};

// If your shield shows colors swapped, set this to true.
const bool INVERT_GREEN = false;

void setOff(uint8_t idx) {
  digitalWrite(LED_PAIRS[idx][0], LOW);
  digitalWrite(LED_PAIRS[idx][1], LOW);
}

void setRed(uint8_t idx, bool on) {
  const uint8_t a = LED_PAIRS[idx][0];
  const uint8_t b = LED_PAIRS[idx][1];
  if (!on) { setOff(idx); return; }
  if (INVERT_GREEN) {
    digitalWrite(a, HIGH);
    digitalWrite(b, LOW);
  } else {
    digitalWrite(a, LOW);
    digitalWrite(b, HIGH);
  }
}

void setup() {
  for (uint8_t i = 0; i < 4; i++) {
    pinMode(LED_PAIRS[i][0], OUTPUT);
    pinMode(LED_PAIRS[i][1], OUTPUT);
    setRed(i, true);
  }
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW); // keep Arduino "L" LED off
}

void loop() {
  // Nothing to do; LEDs stay red.
}




