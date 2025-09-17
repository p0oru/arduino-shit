// Hourly Random Flash
// Keeps LEDs off, then every hour flashes all LEDs with random red/green patterns
// for FLASH_DURATION_MS. Designed for Nano robotics shield (bi-color LEDs on D2–D9).

const uint32_t HOUR_MS = 3600000UL;        // 1 hour
const uint32_t FLASH_DURATION_MS = 15000;  // 15 seconds of random flashing
const uint16_t STEP_MS = 80;               // change pattern every 80 ms

const uint8_t LED_PAIRS[4][2] = {
  {2, 3}, // LED1 pair
  {4, 5}, // LED2 pair
  {6, 7}, // LED3 pair
  {8, 9}  // LED4 pair
};

// If your shield shows colors swapped, set this to true.
const bool INVERT_GREEN = false;

void setOff(uint8_t idx) {
  digitalWrite(LED_PAIRS[idx][0], LOW);
  digitalWrite(LED_PAIRS[idx][1], LOW);
}

void setGreen(uint8_t idx) {
  const uint8_t a = LED_PAIRS[idx][0];
  const uint8_t b = LED_PAIRS[idx][1];
  if (INVERT_GREEN) { digitalWrite(a, LOW); digitalWrite(b, HIGH); }
  else               { digitalWrite(a, HIGH); digitalWrite(b, LOW); }
}

void setRed(uint8_t idx) {
  const uint8_t a = LED_PAIRS[idx][0];
  const uint8_t b = LED_PAIRS[idx][1];
  if (INVERT_GREEN) { digitalWrite(a, HIGH); digitalWrite(b, LOW); }
  else               { digitalWrite(a, LOW);  digitalWrite(b, HIGH); }
}

void allOff() {
  for (uint8_t i = 0; i < 4; i++) setOff(i);
  digitalWrite(LED_BUILTIN, LOW);
}

void flashRandom(uint32_t durationMs, uint16_t stepMs) {
  uint32_t start = millis();
  while ((millis() - start) < durationMs) {
    // Randomize each LED as red or green
    for (uint8_t i = 0; i < 4; i++) {
      if (random(0, 2) == 0) setRed(i); else setGreen(i);
    }
    digitalWrite(LED_BUILTIN, HIGH);
    delay(stepMs);
    // Briefly turn off for a distinct flash
    allOff();
    delay(stepMs);
  }
  allOff();
}

unsigned long lastFlashAtMs = 0;

void setup() {
  for (uint8_t i = 0; i < 4; i++) {
    pinMode(LED_PAIRS[i][0], OUTPUT);
    pinMode(LED_PAIRS[i][1], OUTPUT);
  }
  pinMode(LED_BUILTIN, OUTPUT);
  allOff();

  // Seed randomness from floating analog pin A0
  randomSeed(analogRead(A0));
  lastFlashAtMs = millis();
}

void loop() {
  const unsigned long now = millis();
  if ((now - lastFlashAtMs) >= HOUR_MS) {
    flashRandom(FLASH_DURATION_MS, STEP_MS);
    lastFlashAtMs = millis();
  }
  // Idle; keep LEDs off between events
}


