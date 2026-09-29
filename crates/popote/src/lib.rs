//! Scale recipe quantities between serving counts.
//!
//! A recipe written for four people lists quantities for four. Cooking for six
//! means multiplying every quantity by the same factor, `6 / 4`. This crate
//! does that one computation, and refuses the inputs that have no meaningful
//! answer (zero servings, negative or non-finite quantities) instead of
//! returning `inf` or `NaN` that would propagate silently.
//!
//! ```
//! use popote::scale;
//!
//! // 300 g of flour for 4 servings becomes 450 g for 6.
//! assert_eq!(scale(300.0, 4, 6), Ok(450.0));
//! ```

use std::fmt;

/// Why a quantity could not be scaled.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ScaleError {
    /// The recipe's own serving count is zero, so there is no ratio to apply.
    ZeroServings,
    /// The quantity is negative, infinite or not a number.
    InvalidQuantity,
}

impl fmt::Display for ScaleError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::ZeroServings => f.write_str("the recipe must serve at least one person"),
            Self::InvalidQuantity => {
                f.write_str("the quantity must be a finite, non-negative number")
            }
        }
    }
}

impl std::error::Error for ScaleError {}

/// Scales `quantity`, written for `from` servings, to `to` servings.
///
/// Scaling to zero servings is allowed and returns `0.0`.
///
/// # Errors
///
/// - [`ScaleError::ZeroServings`] when `from` is zero.
/// - [`ScaleError::InvalidQuantity`] when `quantity` is negative, infinite or
///   `NaN`.
///
/// # Examples
///
/// ```
/// use popote::{scale, ScaleError};
///
/// assert_eq!(scale(2.0, 4, 2), Ok(1.0));
/// assert_eq!(scale(2.0, 0, 2), Err(ScaleError::ZeroServings));
/// ```
pub fn scale(quantity: f64, from: u32, to: u32) -> Result<f64, ScaleError> {
    if from == 0 {
        return Err(ScaleError::ZeroServings);
    }
    if !quantity.is_finite() || quantity < 0.0 {
        return Err(ScaleError::InvalidQuantity);
    }
    Ok(quantity * f64::from(to) / f64::from(from))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn scales_up_and_down() {
        assert_eq!(scale(300.0, 4, 6), Ok(450.0));
        assert_eq!(scale(300.0, 6, 4), Ok(200.0));
    }

    #[test]
    fn same_servings_is_identity() {
        assert_eq!(scale(12.5, 3, 3), Ok(12.5));
    }

    #[test]
    fn zero_target_gives_zero() {
        assert_eq!(scale(80.0, 2, 0), Ok(0.0));
    }

    #[test]
    fn zero_source_is_refused() {
        assert_eq!(scale(80.0, 0, 2), Err(ScaleError::ZeroServings));
    }

    #[test]
    fn invalid_quantities_are_refused() {
        for q in [-1.0, f64::NAN, f64::INFINITY, f64::NEG_INFINITY] {
            assert_eq!(scale(q, 2, 4), Err(ScaleError::InvalidQuantity), "{q}");
        }
    }

    #[test]
    fn large_serving_counts_do_not_overflow() {
        // u32 -> f64 is exact, so the ratio is computed without integer overflow.
        assert_eq!(scale(1.0, u32::MAX, u32::MAX), Ok(1.0));
    }

    #[test]
    fn errors_explain_themselves() {
        assert!(
            ScaleError::ZeroServings
                .to_string()
                .contains("at least one")
        );
        assert!(
            ScaleError::InvalidQuantity
                .to_string()
                .contains("non-negative")
        );
    }
}

// Compile and run the README's example as a doctest, so the page crates.io
// shows cannot drift from the API.
#[cfg(doctest)]
#[doc = include_str!("../README.md")]
struct ReadmeDoctests;
