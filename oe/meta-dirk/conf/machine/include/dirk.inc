MACHINE_FEATURES = "usbgadget lua"

IMAGE_FSTYPES += "cramfs tar.bz2"

# Don't include kernels in standard images
RDEPENDS_kernel-base = ""

# Use a common kernel recipe for
PREFERRED_PROVIDER_virtual/kernel ?= "linux"

