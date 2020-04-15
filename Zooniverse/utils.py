#Utils
from panoptes_client import Panoptes, Project

def connect():
    #TODO hash this password.    
    Panoptes.connect(username='bw4sz', password='D!2utNBno8;b')
    everglades_watch = Project.find(10951)
    return everglades_watch