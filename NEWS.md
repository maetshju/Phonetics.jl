# Phonetics.jl release notes

## v0.5.0 (15 May 2025)

This release changes the API for the `phonspec` function. It now permits the use of both Kaiser and Gaussian windows, and allows the user to specify the parameter for the windows. It defaults to a Gaussian with a standard deviation of 1/6. The sample spectrogram in the README and the docs have been updated accordingly.

Additionally, a user can no longer specify a type of spectrogram (as narrow- or broadband). Rather, they must specify the correct window length to do so (approx. 0.005 s for broadband and approx. 0.03 s for narrowband).

There is also a small update to the ordering of package loading, which should resolve an breaking issue where Julia would try to use a system version of OpenSSL instead of the version provided by OpenSSL\_jll.
