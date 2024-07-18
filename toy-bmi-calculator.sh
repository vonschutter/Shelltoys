#!/bin/bash

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
    echo "dialog is not installed. Please install it to proceed."
    exit 1
fi

# Function to display an input box and get the value
get_input() {
    local prompt=$1
    local value=$(dialog --stdout --inputbox "$prompt" 10 30)
    echo $value
}

# Get weight in kilograms
weight=$(get_input "Enter your weight in kilograms:")
if [ -z "$weight" ]; then
    dialog --msgbox "Weight cannot be empty!" 5 30
    clear
    exit 1
fi

# Get height in centimeters
height=$(get_input "Enter your height in centimeters:")
if [ -z "$height" ]; then
    dialog --msgbox "Height cannot be empty!" 5 30
    clear
    exit 1
fi

# Calculate BMI
height_in_meters=$(echo "scale=2; $height / 100" | bc)
bmi=$(echo "scale=2; $weight / ($height_in_meters * $height_in_meters)" | bc)

# Show the result
dialog --msgbox "Your BMI is: $bmi" 10 30

# Clear the screen after dialog closes
clear
