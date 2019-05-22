# Class: pure
# ===========================
#
# This module manages Pure Storage FlashArray devices.
#
# Parameters
# ----------
#
# Variables
# ----------
#
# Examples
# --------
#
# Authors
# -------
#
# Simon Dodsley <simon@purestorage.com>
#
# Copyright
# ---------
#
# Copyright 2017,  Pure Storage, Inc.
#
class pure (
  Boolean $install_purest = false
) {

  if $install_purest {
    package { 'purest':
      ensure   => installed,
      provider => 'puppet_gem'
    }
  }

}
