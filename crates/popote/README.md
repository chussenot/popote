# popote

Scale recipe quantities between serving counts.

A recipe written for four lists quantities for four. `popote::scale` applies
the ratio for any other count, and returns an error instead of `inf` or `NaN`
when the input has no meaningful answer.

```rust
use popote::{scale, ScaleError};

assert_eq!(scale(300.0, 4, 6), Ok(450.0));             // 300 g for 4 -> 450 g for 6
assert_eq!(scale(300.0, 0, 6), Err(ScaleError::ZeroServings));
```

No dependencies, no `unsafe`. Minimum supported Rust version: 1.94.

## License

MIT. See [LICENSE](LICENSE).
