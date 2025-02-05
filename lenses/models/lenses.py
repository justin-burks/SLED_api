from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.core.exceptions import ValidationError
from django.db.models import Q, F, Func, FloatField, CheckConstraint
from django.urls import reverse
from django.conf import settings
import os

import math
from astropy import units as u
from astropy.coordinates import SkyCoord

from . import SingleObject


class ProximateLensManager(models.Manager):
    """
    Attributes:
        check_radius (`float`): A radius in arcsec, representing an area around each existing lens.
    """
    check_radius = 16 # in arcsec
    
    def get_DB_neighbours(self,lens):
        """
        Checks if a lens object (not yet in the database) has any PUBLIC lenses close to it. It excludes itself from the returned queryset (relevant if updating the object).

        Args:
            lens (`Lenses`): A lens around which to search.
            
        Returns:
            neighbours (list `Lenses`): Returns which of the existing lenses in the database are within a 'radius' from the lens.
        """
        qset = super().get_queryset().filter(access_level='PUB').annotate(distance=Func(F('ra'),F('dec'),lens.ra,lens.dec,function='distance_on_sky',output_field=FloatField())).filter(distance__lt=self.check_radius).exclude(id=lens.id)
        if qset.count() > 0:
            return qset
        else:
            return False

    def get_DB_neighbours_anywhere(self,ra,dec,radius=None):
        """
        Same as get_DB_neighbours but this time untied to any lens object (from the database or not).

        Args:
            ra: the RA of any point on the sky.
            dec: the DEC of any point on the sky.
            radius: in arcsec (optional).

        Returns:
            neighbours (list `Lenses`): Returns which of the existing lenses in the database are within a 'radius' from the lens.
        """
        if not radius:
            radius = self.check_radius
        qset = super().get_queryset().filter(access_level='PUB').annotate(distance=Func(F('ra'),F('dec'),ra,dec,function='distance_on_sky',output_field=FloatField())).filter(distance__lt=radius).exclude(id=lens.id)
        if qset.count() > 0:
            return qset
        else:
            return False
        
    def get_DB_neighbours_many(self,lenses):
        """
        Loops over a list of lenses and calls repeatedly get_DB_neighbours.

        Args:
            lenses [List(`Lenses`)]: A list of Lenses objects.

        Returns:
            index_list (List[int]): A list of indices to the original input list indicating those lenses that have proximate existing lenses. 
            neis_list (List[`Lenses`]): Returns which of the existing lenses in the database are within a 'radius' from the lens.
        """   
        index_list = []
        neis_list = [] # A list of non-empty querysets
        for i,lens in enumerate(lenses):
            neis = self.get_DB_neighbours(lens)
            if neis:
                index_list.append(i)
                neis_list.append(neis)
        return index_list,neis_list
    
    
    
class Lenses(SingleObject):    
    ra = models.DecimalField(max_digits=7,
                             decimal_places=4,
                             verbose_name="RA",
                             help_text="The RA of the lens [degrees].",
                             validators=[MinValueValidator(0.0,"RA must be positive."),
                                         MaxValueValidator(360,"RA must be less than 360 degrees.")])
    dec = models.DecimalField(max_digits=6,
                              decimal_places=4,
                              verbose_name="DEC",
                              help_text="The DEC of the lens [degrees].",
                              validators=[MinValueValidator(-90,"DEC must be above -90 degrees."),
                                          MaxValueValidator(90,"DEC must be below 90 degrees.")])
    name = models.CharField(blank=True,
                            max_length=100,
                            help_text="An identification for the lens, e.g. the usual phone numbers.")
    # alt_name = models.CharField(max_length=100,
    #                             help_text="A colloquial name with which the lens is know, e.g. 'The Einstein cross', etc.")  # This could become a comma separated list of names.
    #discovered_at = models.DateField(help_text="The date when the lens was discovered, or the discovery paper published.")
    flag_confirmed = models.BooleanField(default=False,
                                         blank=True,
                                         verbose_name="Confirmed",
                                         help_text="Set to true if the lens has been confirmed by a publication.")
    flag_contaminant = models.BooleanField(default=False,
                                           blank=True,
                                           verbose_name="Contaminant",
                                           help_text="Set to true if the object has been confirmed as NOT a lens by a publication.")
    image_sep = models.DecimalField(blank=True,
                                    null=True,
                                    max_digits=4,
                                    decimal_places=2,
                                    verbose_name="Separation",
                                    help_text="An estimate of the maximum image separation or arc radius [arcsec].",
                                    validators=[MinValueValidator(0.0,"Separation must be positive."),
                                                MaxValueValidator(40,"Separation must be less than 10 arcsec.")])
    z_source = models.DecimalField(blank=True,
                                   null=True,
                                   max_digits=4,
                                   decimal_places=3,
                                   verbose_name="Z source",
                                   help_text="The redshift of the source, if known.",
                                   validators=[MinValueValidator(0.0,"Redshift must be positive"),
                                               MaxValueValidator(20,"If your source is further than that then congrats! (but probably it's a mistake)")])
    z_lens = models.DecimalField(blank=True,
                                 null=True,
                                 max_digits=4,
                                 decimal_places=3,
                                 verbose_name="Z lens",
                                 help_text="The redshift of the lens, if known.",
                                 validators=[MinValueValidator(0.0,"Redshift must be positive"),
                                             MaxValueValidator(20,"If your lens is further than that then congrats! (but probably it's a mistake)")])
    info = models.TextField(blank=True,
                            default='',
                            help_text="Description of any important aspects of this system, e.g. discovery/interesting features/multiple discoverers/etc.")
    
    n_img = models.IntegerField(blank=True,
                                null=True,
                                verbose_name="Number of images",
                                help_text="The number of source images, if known.",
                                validators=[MinValueValidator(2,"For this to be a lens candidate, it must have at least 2 images of the source"),
                                            MaxValueValidator(20,"Wow, that's a lot of images, are you sure?")])
    
    mugshot = models.ImageField(upload_to='lenses')
    #mugshot_name = models.CharField(max_length=100,
    #                                blank=True,
    #                                help_text='File location of the mugshot image, relative to base directory')
    
    ImageConfChoices = (
        ('CUSP','Cusp'),
        ('FOLD','Fold'),
        ('CROSS','Cross'),
        ('DOUBLE','Double'),
        ('QUAD','Quad'),
        ('RING','Ring'),
        ('ARCS','Arcs')
    )
    image_conf = models.CharField(max_length=100,
                                  blank=True,
                                  null=True,
                                  choices=ImageConfChoices,
                                  verbose_name="Configuration")
    
    LensTypeChoices = (
        ('GALAXY','Galaxy'),
        ('GROUP','Group of galaxies'),
        ('CLUSTER','Galaxy cluster'),
        ('QUASAR','Quasar')
    )
    lens_type = models.CharField(max_length=100,
                                 blank=True,
                                 null=True,
                                 choices=LensTypeChoices)
    
    SourceTypeChoices = (
        ('GALAXY','Galaxy'),
        ('QUASAR','Quasar'),
        ('GW','Gravitational Wave'),
        ('FRB','Fast Radio Burst'),
        ('GRB','Gamma Ray Burst'),
        ('SN','Supernova')
    )
    source_type = models.CharField(max_length=100,
                                   blank=True,
                                   null=True,
                                   choices=SourceTypeChoices)

    
    proximate = ProximateLensManager()
    objects = models.Manager()

    class Meta():
        db_table = "lenses"
        verbose_name = "lens"
        verbose_name_plural = "lenses"
        ordering = ["ra"]
        # The constraints below should encompass both field Validators above, and the clean method below.
        constraints = [
            CheckConstraint(check=Q(n_img__range=(2,20)),name='n_img_range'),
            CheckConstraint(check=Q(z_lens__range=(0,20)),name='z_lens_range'),
            CheckConstraint(check=Q(z_source__range=(0,20)),name='z_source_range'),
            CheckConstraint(check=Q(ra__range=(0,360)),name='ra_range'),
            CheckConstraint(check=Q(dec__range=(-90,90)),name='dec_range'),
            CheckConstraint(check=Q(image_sep__range=(0,40)),name='image_sep_range'),
            CheckConstraint(check=Q(z_lens__lt=F('z_source')),name='z_lens_lt_z_source'),
            CheckConstraint(check=~(Q(flag_confirmed=True) & Q(flag_contaminant=True)),name='flag_check'),
            CheckConstraint(check=~( Q(flag_contaminant=True) &
                                     (
                                         (Q(image_conf__isnull=False) | ~Q(image_conf__exact='')) |
                                         (Q(lens_type__isnull=False) | ~Q(lens_type__exact='')) |
                                         (Q(source_type__isnull=False) | ~Q(source_type__exact=''))
                                     )
                                    ),
                            name='contaminant_check'),
        ]

    def clean(self):
        if self.flag_confirmed and self.flag_contaminant: # flag_check
            raise ValidationError('The object cannot be both a lens and a contaminant.')
        if self.flag_contaminant and (self.image_conf or self.lens_type or self.source_type): # contaminant_check
            raise ValidationError('The object cannot be a contaminant and have a lens or source type, or an image configuration.')
        if self.z_lens and self.z_source: # z_lens_lt_z_source
            if self.z_lens > self.z_source:
                raise ValidationError('The source redshift cannot be lower than the lens redshift.')

    def save(self,*args,**kwargs):
	# Call save first, to create a primary key
        super(Lenses,self).save(*args,**kwargs)
        
        fname = '/'+self.mugshot.name
        sled_fname = '/lenses/' + str( self.pk ) + '.png'
        
        # Create new file and remove old one
        if fname != sled_fname:
            os.rename(settings.MEDIA_ROOT+fname,settings.MEDIA_ROOT+sled_fname)
            self.mugshot.name = sled_fname
            super(Lenses,self).save(*args,**kwargs)


    def __str__(self):
        if self.name:
            return self.name
        else:
            c = SkyCoord(ra=self.ra*u.degree, dec=self.dec*u.degree, frame='icrs')
            return 'J'+c.to_string('hmsdms')

    def create_name(self):
        c = SkyCoord(ra=self.ra*u.degree, dec=self.dec*u.degree, frame='icrs')
        self.name = 'J'+c.to_string('hmsdms')
        
    def get_absolute_url(self):
        return reverse('lenses:lens-detail',kwargs={'pk':self.id})

    def get_DB_neighbours(self,radius):
        neighbours = list(Lenses.objects.filter(access_level='PUB').annotate(distance=Func(F('ra'),F('dec'),self.ra,self.dec,function='distance_on_sky',output_field=FloatField())).filter(distance__lt=radius))
        return neighbours

    @staticmethod
    def distance_on_sky(ra1,dec1,ra2,dec2):
        """
        This is the same implementation of the distance between a points on a sphere and the lens as the function 'distance_on_sky' in the database.

        Attributes:
            ra1,dec1 (`float`): the ra and dec of a point on the sphere. If not given, then the lens coordinates are used.
            ra2,dec2 (`float`): the ra and dec of another point.

        Returns:
            distance (`float`): the distance between the lens and the given point in arcsec.
        """
        dec1_rad = math.radians(dec1);
        dec2_rad = math.radians(dec2);
        Ddec = abs(dec1_rad - dec2_rad);
        Dra = abs(math.radians(ra1) - math.radians(ra2));
        a = math.pow(math.sin(Ddec/2.0),2) + math.cos(dec1_rad)*math.cos(dec2_rad)*math.pow(math.sin(Dra/2.0),2);
        d = math.degrees( 2.0*math.atan2(math.sqrt(a),math.sqrt(1.0-a)) )
        return d*3600.0
