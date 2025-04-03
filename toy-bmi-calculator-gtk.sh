#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install required packages on Debian-based systems
install_debian() {
    sudo apt-get update
    sudo apt-get install -y yad bc
}

# Function to install required packages on Red Hat-based systems
install_redhat() {
    sudo yum install -y yad bc
}

# Detect the operating system and install yad and bc if not present
if ! command_exists yad || ! command_exists bc; then
    if [ -f /etc/debian_version ]; then
        install_debian
    elif [ -f /etc/redhat-release ]; then
        install_redhat
    else
        echo "Unsupported OS. Please install 'yad' and 'bc' manually."
        exit 1
    fi
fi

# Function to display an input box and get the value
get_input() {
    local prompt=$1
    local value=$(yad --entry --title="BMI Calculator" --text="$prompt" --width=300 --center)
    echo $value
}

# Get weight in kilograms
weight=$(get_input "Enter your weight in kilograms:")
if [ -z "$weight" ]; then
    yad --info --title="Error" --text="Weight cannot be empty!" --width=300 --center
    clear
    exit 1
fi

# Get height in centimeters
height=$(get_input "Enter your height in centimeters:")
if [ -z "$height" ]; then
    yad --info --title="Error" --text="Height cannot be empty!" --width=300 --center
    clear
    exit 1
fi

# Ensure weight and height are numeric
if ! [[ "$weight" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    yad --info --title="Error" --text="Weight must be a numeric value!" --width=300 --center
    clear
    exit 1
fi

if ! [[ "$height" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    yad --info --title="Error" --text="Height must be a numeric value!" --width=300 --center
    clear
    exit 1
fi

# Calculate BMI
height_in_meters=$(echo "scale=2; $height / 100" | bc)
bmi=$(echo "scale=2; $weight / ($height_in_meters * $height_in_meters)" | bc)

# Interpretation and Recommendation based on BMI
if (( $(echo "$bmi < 18.5" | bc -l) )); then
    interpretation="Underweight"
    recommendation="It's important to eat a balanced diet and consider consulting with a healthcare provider."
elif (( $(echo "$bmi >= 18.5 && $bmi < 24.9" | bc -l) )); then
    interpretation="Normal weight"
    recommendation="Maintain your current routine and stay active."
elif (( $(echo "$bmi >= 25 && $bmi < 29.9" | bc -l) )); then
    interpretation="Overweight"
    recommendation="Consider a balanced diet and regular exercise. Consult with a healthcare provider for personalized advice."
else
    interpretation="Obese"
    recommendation="It's important to consult with a healthcare provider for a comprehensive health plan."
fi

# Show the result
yad --info --title="BMI Result" --text="Your BMI is: $bmi\n\nInterpretation: $interpretation\n\nRecommendation: $recommendation" --width=400 --center

# Clear the screen after yad closes
clear
