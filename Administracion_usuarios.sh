function removeSecondaryGroup ()
{
	clear
	echo has seleccionado la opción de eliminar un grupo secundario
	echo indica el nombre del grupo del que quieres expulsar al usuario
	read groupToDelete
	local groupToDeleteCheck=$(grep $groupToDelete: /etc/group)

	if [ -n "$groupToDeleteCheck" ]
	then
		local userInGroup=$(grep $groupToDeleteCheck /etc/group | cut -f 4 -d : | grep ,*$1,*)
		if [ -n "$userInGroup" ]
		then
			touch aux
			local groupID=$(grep $groupToDelete: /etc/group | cut -f 3 -d :)
			local usersWithSpace=$(grep $groupToDelete: /etc/group | cut -f 4 -d : | tr ',' ' ')
			local counter=0
			for nameUsers in $usersWithSpace
			do
				if [ "$nameUsers" != "$1" ]
				then
					if [ "$counter" -eq 0 ]
					then
						echo -n $nameUsers >> aux
					else
						echo -n ,$nameUsers >> aux
					fi
				fi
				local counter=1

			done
			local usersWithoutHim=$(cat aux)
			rm aux
			local groupToWrite=$groupToDelete:x:$groupID:$usersWithoutHim
			touch aux
			grep -v $groupToDelete: /etc/group > aux
			echo $groupToWrite >> aux
			cat aux | sort -k3 -t: -n > /etc/group
			rm aux
			echo completada la acción de eliminación de grupo secundario
			echo volvemos al menú de modificación de usuario
			echo
		else
			echo el usuario no tiene asignado este grupo como secundario
			echo volvemos al menú de modificación de usuario
			echo
		fi

	else
		echo el grupo indicando no existe
		echo podríamos considerar un éxito la operación
		echo
		echo volvemos al menú de modificación de usuario
		echo
	fi
}

function addSecondaryGroup ()
{
clear
echo has seleccionado la opción de adición de grupo secundario
echo indica el nombre del grupo que deseas añadir
read newGroup
local newGroupChecked=$(grep $newGroup: /etc/group)

	if [ -n "$newGroupChecked" ]
	then
		local groupID=$(grep $newGroupChecked /etc/group | cut -f 3 -d :)
		local usersInGroup=$(grep $newGroupChecked /etc/group | cut -f 4 -d :)
		if [ -z "$usersInGroup" ]
		then
			groupToWrite=$newGroup:x:$groupID:$1
			touch aux
			grep -v $newGroup: /etc/group > aux
			echo $groupToWrite >> aux
			cat aux | sort -k3 -t: -n > /etc/group
			rm aux
			echo el grupo se ha asignado correctamente
			echo volvemos al menú de modificación de usuario
			echo

		else
			local usersWithSpace=$(grep $groupToWrite: /etc/group | cut -f 4 -d : | tr ',' ' ')
			for nameUsers in $usersWithSpace
			do
				if [ "$nameUsers" = "$1" ]
				then
					local thisUserInGroup=$nameUsers
				fi
			done
			if [ -z "$thisUserInGroup" ]
			then
				groupToWrite=$newGroup:x:$groupID:$usersInGroup,$1
				touch aux
				grep -v $newGroup: /etc/group > aux
				echo $groupToWrite >> aux
				cat aux | sort -k3 -t: -n > /etc/group
				rm aux
				echo el grupo se ha asignado satisfactoriamente
				echo volvemos al menú de modificación de usuario
				echo
			else
				echo
				echo el usuario ya tenía asignado ese grupo como secundario
				echo se lo habías asignado tú hace tiempo
				echo
				echo volvemos al menú de modificación de usuario
			fi
		fi


	else
		echo
		echo no puedes añadir un grupo inexistente
		echo hay muchos para escoger
		echo
		echo volvemos al menú de modificación de usuario
		echo
	fi
}

function changeGroup ()
{
	clear
	local userData=$(grep $1 /etc/passwd)
	echo has seleccionado cambiar el grupo principal
	echo indica el nombre del grupo al que quieres cambiarlo
	read newGroup
	local newGroupChecked=$(grep $newGroup: /etc/group)
	if [ -n "$newGroupChecked" ]
	then
		local userID=$(grep $1: /etc/passwd | cut -f 3 -d :)
		local groupID=$(grep $1: /etc/passwd | cut -f 4 -d :)
		local userDetails=$(grep $1: /etc/passwd | cut -f 5 -d :)
		local userDir=$(grep $1: /etc/passwd | cut -f 6 -d :)
		local shell=$(grep $1: /etc/passwd | cut -f 7 -d :)
		newGroupID=$(grep $newGroupChecked /etc/group | cut -f 3 -d :)
		newUser=$1:x:$userID:$newGroupID:$userDetails:$userDir:$shell
		if [ $groupID -eq $newGroupID ]
		then
			echo
			echo el usuario ya pertenece a ese grupo
			echo veo que te gusta perder el tiempo
			echo retrocedemos al menú de modificación de usuario
			echo
		else
			touch aux
			grep -v $1: /etc/passwd > aux
			echo $newUser >> aux
			cat aux | sort -k3 -t: -n > /etc/passwd
			rm aux
			echo el grupo principal ha sido cambiado satisfactoriamente
			echo estarás contento
			echo volvemos al menú de modificación de usuario
			echo
		fi
	else
		echo
		echo el grupo no existe en el sistema
		echo a la próxima seguro que aciertas, ya verás
		echo
		echo volvemos al menú de modificación de usuario
		echo
	fi
}


function userModification ()
{
	local choice=1
	clear
	echo has seleccionado la opción para modificar usuario
	echo introduce el nombre del usuario que quieres modificar
	read userName
	local userData=$(grep $userName: /etc/passwd | cut -f 1 -d :)
	if [ -n "$userData" ]
	then
		while [ $choice != 0 ]
		do
			echo
			echo indica con un entero qué deseas modificar
			echo
			echo 1. Grupo principal
			echo 2. Añadir grupo secundario
			echo 3. Eliminar grupo secundario
			echo 0. Volver al menú principal
			read choice
			case $choice in
				1)changeGroup $userName;;
				2)addSecondaryGroup $userName;;
				3)removeSecondaryGroup $userName;;
				0)echo volvemos al menú principal
				echo;;
				*)echo Esa opción no existe. Lo sentimos;;
			esac
		done

	else
		echo
		echo el usuario no existe en el sistema
		echo hoy estás despistado, eh?
		echo volvemos al menú principal
		echo
	fi
}

function userCreator ()
{
	clear
	echo has seleccionado la opción para crear usuario
	echo introduce el nombre de usuario que quieres crear
	read userName
	local userExistence=$(grep $userName: /etc/passwd | cut -f 1 -d :)
	if [ -z "$userExistence" ]
	then
		local shell=/bin/bash
		local detailsUser=$userName,,,
		local userFolder=/home/$userName
		local biggestID=$(tail -n1 /etc/passwd | cut -f 3 -d :)
		local biggestIDGroup=$(tail -n1 /etc/group | cut -f 3 -d :)
		local newID=$(($biggestID + 1))
		local newIDGroup=$(($biggestIDGroup + 1))


		local userComplete=$userName:x:$newID:$newIDGroup:$detailsUser:$userFolder:$shell
		local groupComplete=$userName:x:$newIDGroup:

		echo $userComplete >> /etc/passwd
		echo $groupComplete >> /etc/group

		mkdir $userFolder
		chmod -R 750 $userFolder
		chown -R $userName:$userName $userFolder

		echo Usuario creado correctamente
		echo Por favor, introdúcele un password
		echo
		passwd $userName
		echo volvemos al menú principal
		echo
	else

		echo
		echo el usuario ya existe en el sistema
		echo hay que ser más original con los nombres
		echo volvemos al menú de inicio
		echo
	fi

}


function showUsers ()
{
	clear
	echo has seleccionado la opción para ver todos los usuarios
	echo por favor, pulsa intro para continuar
	read
	cut -f 1 -d : /etc/passwd | more
	echo
	echo esos son todos los usuarios registrados en el sistema
	echo ¿qué deseas hacer ahora?
}

function userDetails ()
{
	clear
	echo has seleccionado la opción para consultar datos de un usuario
	echo por favor, introduce el nombre a buscar
	read userName
	local userData=$(grep $userName: /etc/passwd | cut -f 1 -d :)


	if [ -n "$userData" ]
	then
		local userID=$(cut -f 1,3,4 -d : /etc/passwd | grep $userName: | cut -f 2 -d :)
		local groupID=$(cut -f 1,3,4 -d : /etc/passwd | grep $userName: | cut -f 3 -d :)
		local groupPrincipal=$(grep :$groupID: /etc/group | cut -f 1 -d :)
		local groupSecondary=$(grep [:,]$userName /etc/group | cut -f 1 -d :)
		echo -n nombre:
		echo $userName
		echo -n userID:
		echo $userID
		echo -n grupo principal:
		echo $groupPrincipal
		echo -n grupos secundarios:
		if [ -n "$groupSecondary" ]
		then
			echo $groupSecondary
		else
			echo no tiene grupos secundarios
		fi

		echo
		echo esa es toda la información que te podemos dar
		echo volvemos al menú principal

	else
		echo
		echo el usuario no existe en nuestro sistema
		echo a ver si llevamos un mejor control del personal
		echo volvemos al menú de inicio
		echo
	fi

}

function changePasswd ()
{
	clear
	echo has escogido la opción de modificar contraseña
	echo indica el nombre del usuario al que se la quieres cambiar
	read userName
	local userExsist=$(grep $userName: /etc/passwd | cut -f 1 -d :)
	if [ -n "$userName" ]
	then
		passwd $userName
		echo
		echo bash ha hecho su trabajo
		echo volvemos al menú principal
		echo
	else
		echo
		echo el usuario no existe en el sistema
		echo volvemos al menú principal
		echo
	fi
}

clear
echo bienvenido a tu nuevo asistente de creación de usuarios
echo
choice=1

while [ $choice !=  0 ]
do

	echo por favor, indica con un entero qué deseas hacer:
	echo
	echo 1. Ver todos los usuarios.
	echo 2. Mostrar datos de un usuario concreto.
	echo 3. Añadir un nuevo usuario.
	echo 4. Modificar un usuario.
	echo 5. Modificar la contraseña de un usuario.
	echo 0. Salir.

	read choice

	case $choice in
		1)showUsers;;
		2)userDetails;;
		3)userCreator;;
		4)userModification;;
		5)changePasswd;;
		0)echo bye bye;;
		*)echo no intentes jugármela. Esa opción no está en el menú;;
	esac
done
