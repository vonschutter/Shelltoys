#!/bin/bash
BMI_CALCULATOR_VERSION="1.01"
PUBLICATION="BMI Calculator   Version: ${BMI_CALCULATOR_VERSION} "
#
#


dependency::file ()
{
	local _src_url="https://github.com/${_GIT_PROFILE:-vonschutter}/RTD-Setup/raw/main/core/${1}"
	local _tgt="${1}"

	dependency::search_local ()
	{
		echo "${FUNCNAME[0]}: Requested dependency file: ${1} ..."

		for i in "./${1}" \
                 "../core/${1}" \
                 "../../core/${1}" \
                 "${0%/*}/../core/${1}" \
                 "${0%/*}/../../core/${1}" \
                 "$(find /opt -name ${1} \
                 |grep -v bakup )" ; do 
			echo "${FUNCNAME[0]}: Searching for ${i} ..."
			if [[ -e "${i}" ]] ; then 
				echo "${FUNCNAME[0]}: Found ${i}"
				source "${i}" ""
				return 0
			fi
		done
		return 1
	}

	if dependency::search_local "${1}" ; then
		return 0
	else
		echo "$(date) failure to find $1 on the local comuter, now searching online..."
		if curl -sL "$_src_url" | source /dev/stdin ; then 
			echo "${FUNCNAME[0]} Using: ${_src_url} directly from URL..."
		elif wget "${_src_url}" &>/dev/null ; then
			source ./"${1}"
			echo "${FUNCNAME[0]} Using: ${_src_url} downloaded..."
		else 
			echo "${FUNCNAME[0]} Failed to find  ${1} "
			exit 1
		fi
	fi 
}

dependency::file "_rtd_library"


# Detect the operating system and install yad and bc if not present
if ! dependency::command_exists yad || ! dependency::command_exists bc; then
    software::check_native_package_dependency yad
    software::check_native_package_dependency bc
fi

# Function to display an input box and get the value
bmi::get_input() {
    local prompt=$1
    local value=$(yad --entry --title="${PUBLICATION}" --text="$prompt" --width=300 --center)
    echo $value
}

# Get weight in kilograms
weight=$(bmi::get_input "Enter your weight in kilograms:")
if [ -z "$weight" ]; then
    yad --info --title="${PUBLICATION}: Error" --text="Weight cannot be empty!" --width=300 --center
    clear
    exit 1
fi

# Get height in centimeters
height=$(bmi::get_input "Enter your height in centimeters:")
if [ -z "$height" ]; then
    yad --info --title="${PUBLICATION}: Error" --text="Height cannot be empty!" --width=300 --center
    clear
    exit 1
fi

# Ensure weight and height are numeric
if ! [[ "$weight" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    yad --info --title="${PUBLICATION}: Error" --text="Weight must be a numeric value!" --width=300 --center
    clear
    exit 1
fi

if ! [[ "$height" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    yad --info --title="${PUBLICATION}: Error" --text="Height must be a numeric value!" --width=300 --center
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
yad --info --title="${PUBLICATION}: BMI Result" --text="Your BMI is: $bmi\n\nInterpretation: $interpretation\n\nRecommendation: $recommendation" --width=400 --center

# Clear the screen after yad closes
clear
