from ..Models import Base
from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Unicode,
    text,
    Sequence,
    orm,
    func,
    select,
    bindparam,
    UniqueConstraint,
    event)
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.orm import relationship
from ..GenericObjets.ObjectWithDynProp import ObjectWithDynProp
from ..GenericObjets.ObjectTypeWithDynProp import ObjectTypeWithDynProp
from traceback import print_exc
from datetime import datetime


class Station(Base, ObjectWithDynProp):

    __tablename__ = 'Station'

    ID = Column(Integer, Sequence('Stations__id_seq'), primary_key=True)
    StationDate = Column(DateTime, index=True, nullable=False)
    Name = Column(String(250))
    LAT = Column(Numeric(9, 5))
    LON = Column(Numeric(9, 5))
    ELE = Column(Integer)
    precision = Column(Integer)
    fieldActivityId = Column(Integer, ForeignKey(
        'fieldActivity.ID'), nullable=True)
    creator = Column(Integer)
    creationDate = Column(DateTime, default=func.now())
    Observations = relationship(
        'Observation', back_populates='Station', cascade="all, delete-orphan")
    StationDynPropValues = relationship(
        'StationDynPropValue', backref='Station', cascade="all, delete-orphan")
    FK_StationType = Column(Integer, ForeignKey('StationType.ID'))
    Comments = Column(String(250))

    FK_Region = Column(Integer, ForeignKey('Region.ID'), nullable=True)
    FK_MonitoredSite = Column(Integer, ForeignKey(
        'MonitoredSite.ID'), nullable=True)

    Place = Column(String(250))

    Station_FieldWorkers = relationship(
        'Station_FieldWorker', backref='Station', cascade="all, delete-orphan")
    __table_args__ = (UniqueConstraint('StationDate', 'LAT', 'LON',
                                       name='_unique_constraint_lat_lon_date'),
                      {'implicit_returning': False})

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        ObjectWithDynProp.__init__(self)

    ''' hybrid property on relationship '''
    @hybrid_property
    def FieldWorkers(self):
        if self.Station_FieldWorkers:
            fws = []
            for curFW in self.Station_FieldWorkers:
                fws.append(
                    {'FieldWorker': curFW.FK_FieldWorker, 'ID': curFW.ID})
            return fws
        else:
            return []

    ''' Configure a setter for this hybrid property '''
    @FieldWorkers.setter
    def FieldWorkers(self, values):
        fws = []
        if len(values) != 0:
            for item in values:
                if 'ID' in item and item['ID'] is not None:
                    curFW = list(filter(lambda x: x.ID == item[
                                 'ID'], self.Station_FieldWorkers))[0]
                    curFW.FK_FieldWorker = int(item['FieldWorker'])
                else:
                    curFW = Station_FieldWorker(FK_FieldWorker=int(
                        item['FieldWorker']), FK_Station=self.ID)
                fws.append(curFW)
        self.Station_FieldWorkers = fws

    @FieldWorkers.expression
    def FieldWorkers(cls):
        return Station_FieldWorker.id

    @orm.reconstructor
    def init_on_load(self):
        ''' init_on_load is called on the fetch of object '''
        ObjectWithDynProp.__init__(self)

    def GetNewValue(self, nameProp):
        ReturnedValue = StationDynPropValue()
        try:
            ReturnedValue.FK_StationDynProp = self.ObjContext.execute(
                select([StationDynProp.ID]).where(StationDynProp.Name == nameProp)).scalar()
        except:
            print_exc()
        return ReturnedValue

    def GetDynPropValues(self):
        return self.StationDynPropValues

    def GetDynProps(self, nameProp):
        return self.ObjContext.query(StationDynProp).filter(StationDynProp.Name == nameProp).one()

    def GetType(self):
        if self.StationType is not None:
            return self.StationType
        else:
            return self.ObjContext.query(StationType).get(self.FK_StationType)

    def allowUpdate(self, DTOObject):
        from ..utils.parseValue import isNumeric

        allow = True
        site = None
        if 'FK_MonitoredSite' in DTOObject:
            site = int(DTOObject['FK_MonitoredSite']) if isNumeric(DTOObject['FK_MonitoredSite']) else None
        dateSta = datetime.strptime(DTOObject['StationDate'], '%d/%m/%Y %H:%M:%S')
        equipmentExist = self.existingProtocolEquipment()

        if equipmentExist and (
            self.FK_MonitoredSite != site or self.StationDate != dateSta):
            allow = False
        return allow

    def existingProtocolEquipment(self):
        protolist = list(filter(lambda x: x.GetType().Name.lower() in ['site_equipment',
                                                                       'site_unequipment',
                                                                       'individual_unequipment',
                                                                       'individual_unequipment'], self.Observations))
        return len(protolist) > 0


@event.listens_for(Station, 'before_insert')
@event.listens_for(Station, 'before_update')
def updateRegion(mapper, connection, target):
    if target.LON and target.LAT:
        stmt = text('''SELECT dbo.[fn_GetRegionFromLatLon] (:lat,:lon)
        ''').bindparams(bindparam('lat', target.LAT),
                        bindparam('lon', target.LON))
        regionID = connection.execute(stmt).scalar()
        target.FK_Region = regionID


class StationDynProp(Base):

    __tablename__ = 'StationDynProp'

    ID = Column(Integer, Sequence('StationDynProp__id_seq'), primary_key=True)
    Name = Column(Unicode(250), nullable=False)
    TypeProp = Column(Unicode(250), nullable=False)
    StationType_StationDynProps = relationship(
        'StationType_StationDynProp', backref='StationDynProp')
    StationDynPropValues = relationship(
        'StationDynPropValue', backref='StationDynProp')


class StationDynPropValue(Base):

    __tablename__ = 'StationDynPropValue'

    ID = Column(Integer, Sequence(
        'StationDynPropValue__id_seq'), primary_key=True)
    StartDate = Column(DateTime, nullable=False)
    ValueInt = Column(Integer)
    ValueString = Column(String(250))
    ValueDate = Column(DateTime)
    ValueFloat = Column(Numeric(12, 5))
    FK_StationDynProp = Column(Integer, ForeignKey('StationDynProp.ID'))
    FK_Station = Column(Integer, ForeignKey('Station.ID'))


class StationType(Base, ObjectTypeWithDynProp):

    @orm.reconstructor
    def init_on_load(self):
        ObjectTypeWithDynProp.__init__(self)

    __tablename__ = 'StationType'

    ID = Column(Integer, Sequence('StationType__id_seq'), primary_key=True)
    Name = Column(Unicode(250))
    Status = Column(Integer)
    StationType_StationDynProp = relationship(
        'StationType_StationDynProp', backref='StationType')
    Stations = relationship('Station', backref='StationType')


class StationType_StationDynProp(Base):

    __tablename__ = 'StationType_StationDynProp'

    ID = Column(Integer, Sequence(
        'StationType_StationDynProp__id_seq'), primary_key=True)
    Required = Column(Integer, nullable=False)
    FK_StationType = Column(Integer, ForeignKey('StationType.ID'))
    FK_StationDynProp = Column(Integer, ForeignKey('StationDynProp.ID'))


class Station_FieldWorker (Base):

    __tablename__ = 'Station_FieldWorker'

    ID = Column(Integer, Sequence(
        'Station_FieldWorker__id_seq'), primary_key=True)
    FK_Station = Column(Integer, ForeignKey('Station.ID'))
    FK_FieldWorker = Column(Integer, ForeignKey('User.ID'))

    FieldWorker = relationship('User')

    @hybrid_property
    def FieldWorkerName(self):
        if self.FieldWorker:
            return self.FieldWorker.Login
        else:
            return None

    @hybrid_property
    def FieldWorkerID(self):
        if self.FieldWorker:
            return self.FieldWorker.id
        else:
            return None
