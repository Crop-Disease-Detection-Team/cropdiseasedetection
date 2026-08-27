from decouple import config
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

class Command(BaseCommand):
    help = 'Creates the default administrator account if it does not exist.'

    def handle(self, *args, **kwargs):
        User = get_user_model()
        username = config('DEFAULT_ADMIN_USERNAME', default='admin')
        email = config('DEFAULT_ADMIN_EMAIL', default='admin@agrivision.ai')
        password = config('DEFAULT_ADMIN_PASSWORD', default='Admin@123')

        if not User.objects.filter(username=username).exists():
            User.objects.create_superuser(
                username=username,
                email=email,
                password=password,
                full_name='Administrator',
                role='admin',
            )
            self.stdout.write(self.style.SUCCESS('Successfully created default administrator account.'))
        else:
            self.stdout.write(self.style.WARNING('Administrator account already exists.'))
