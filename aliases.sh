alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias g=git
alias gt=git
alias gti=git

alias cc=claude
alias oc=opencode
alias cld=claude
alias cpt=copilot
alias gmn=gemini

alias y=yazi

alias v=nvim
alias vi=nvim
alias vim=nvim
alias nv=nvim

# Maven
alias m=mvn
alias mvnt='mvn test'
alias mvnc='mvn clean'
alias mvnp='mvn package'
alias mvni='mvn install'
alias mvnd='mvn deploy'
alias mvnci='mvn clean install'
alias mvncp='mvn clean package'
alias mvncd='mvn clean deploy'
alias mvnsbr='mvn spring-boot:run'

mvnsbrp() {
  mvn spring-boot:run -Dspring-boot.run.profiles="$1"
}

alias sudo='sudo '
alias plz=sudo

alias clr=clear
alias clra=clear
alias cler=clear
alias clera=clear

alias j="jobs"
alias h="history"

# AWS
alias aws-whoami='aws sts get-caller-identity'

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'
