#!/usr/bin/env bash

# Enabling Font Smoothing
defaults write -g CGFontRenderingFontSmoothingDisabled -bool NO

# Light font smoothing
#defaults -currentHost write -globalDomain AppleFontSmoothing -int 3

# Medium font smoothing
#defaults -currentHost write -globalDomain AppleFontSmoothing -int 2

# Strong font smoothing
defaults -currentHost write -globalDomain AppleFontSmoothing -int 3
