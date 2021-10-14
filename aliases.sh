
# OS specific stuff
if [[ $OSTYPE =~ darwin ]]; then
  alias brwe='brew'
  alias systemctl='brew services'
  alias services='brew services'
  alias service='brew services'
fi

# always use vim instead of vi
alias vi=vim

alias ..="cd .."
alias cd..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Git
alias g=git
alias gt=git
alias gti=git

# Docker
alias d=docker
alias k=kubectl
alias kaf='kubectl apply -f'
alias kg='kubectl get'
alias kd='kubectl describe'

# AWS
alias aws-whoami='aws sts get-caller-identity'

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

# Enable aliases to be sudo’ed
alias sudo='sudo '
alias plz=sudo

alias clr=clear
alias clra=clear
alias cler=clear
alias clera=clear

alias j="jobs"
alias h="history"

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'
