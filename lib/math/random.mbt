// ============================================================
// Pseudo-Random Number Generator (PRNG)
// ============================================================

///|
/// LCG-based pseudo-random number generator for simulations.
pub struct PRNG {
  mut state : Int64
}

///|
/// Create a new PRNG with a seed.
pub fn PRNG::new(seed : Int) -> PRNG {
  { state: seed.to_int64() }
}

///|
/// Generate next 32-bit integer.
pub fn PRNG::next_int(self : PRNG) -> Int {
  let a : Int64 = 6364136223846793005L
  let c : Int64 = 1442695040888963407L
  self.state = self.state * a + c
  (self.state >> 32).to_int()
}

///|
/// Generate next uniform double in [0, 1).
pub fn PRNG::next_double(self : PRNG) -> Double {
  let val = self.next_int()
  let positive_val = if val < 0 { -val } else { val }
  (positive_val % 1000000).to_double() / 1000000.0
}

///|
/// Generate next uniform double in range [min, max].
pub fn PRNG::next_uniform(self : PRNG, min : Double, max : Double) -> Double {
  min + (max - min) * self.next_double()
}

///|
/// Generate standard normal random variable using Box-Muller transform.
pub fn PRNG::next_normal(self : PRNG, mean : Double, std : Double) -> Double {
  let mut u1 = self.next_double()
  while u1 <= 1.0e-10 {
    u1 = self.next_double()
  }
  let u2 = self.next_double()
  let r = sqrt_approx(-2.0 * ln_approx(u1))
  let theta = 2.0 * pi * u2
  let z0 = r * exp_approx(0.0) * (if theta > pi { -1.0 } else { 1.0 }) // approximation
  mean + std * z0
}

///|
/// Shuffle an array in-place using Fisher-Yates algorithm.
pub fn[T] PRNG::shuffle(self : PRNG, arr : Array[T]) -> Unit {
  let n = arr.length()
  for i = n - 1; i > 0; i = i - 1 {
    let raw_j = self.next_int()
    let j_pos = if raw_j < 0 { -raw_j } else { raw_j }
    let j = j_pos % (i + 1)
    let temp = arr[i]
    arr[i] = arr[j]
    arr[j] = temp
  }
}

///|
/// Sample n items with replacement from an array.
pub fn[T] PRNG::sample_with_replacement(
  self : PRNG,
  arr : Array[T],
  n : Int,
) -> Array[T] {
  let len = arr.length()
  let result : Array[T] = []
  if len == 0 {
    return result
  }
  for _i = 0; _i < n; _i = _i + 1 {
    let raw_idx = self.next_int()
    let idx_pos = if raw_idx < 0 { -raw_idx } else { raw_idx }
    let idx = idx_pos % len
    result.push(arr[idx])
  }
  result
}
