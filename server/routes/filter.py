from fastapi import HTTPException, APIRouter, Depends
import uuid
from models.filters_model import Filters
from models.objects_model import ThreeDObjectsModel

#app = FastAPI() # lets not make another instance
router = APIRouter() # OFFERS ALL OF THE FUNCTIONALITY AS APP

example_filters = {
    "filters": [
        {"type": "vertex", "minValue": None, "maxValue": None},
        {"type": "bones", "minValue": None, "maxValue": None},
        {"type": "edges", "minValue": None, "maxValue": None},
        {"type": "poly", "minValue": None, "maxValue": None},
        {"type": "mesh", "minValue": None, "maxValue": None},
        {"type": "armature", "minValue": None, "maxValue": None},
    ]
}
example_glbs_1 = [
    "8476c4170df24cf5bbe6967222d1a42d",
    "8ff7f1f2465347cd8b80c9b206c2781e",
    "dcd33159a0864de388de3a08f55e604a",
    "a7ad32b5d4d84ee5a40ebbd86da4dbe4",
    "7d6a14874eed48c2b720f0d1adfe6dd9"
]

example_glbs_2 = [
    "71c71dd1dc754a8e9a84d43f5f3af7b9",
    "1ce26e72d2dc4c66aca37a8124671a2f",
    "3564578cde5c42279ead680df1619e3c",
    "f9e1f80dab694ef1a3a85f135266c46f",
    "1e782aa8ca9e4dada94aabcb463086ae"
]
@router.get("/options", response_model=Filters, status_code=200)
def fetch_filters():
    return example_filters



@router.post("/apply", response_model=ThreeDObjectsModel, status_code=200)
def apply_filters(filters: Filters):
    """
    Apply filters to determine which example data to return.
    If any maxValue > 7 or any minValue < 3, return example_glbs_2.
    Otherwise, return example_glbs_1.
    """
    for filter_item in filters.filters:
        if (filter_item.maxValue is not None and filter_item.maxValue > 7) or \
           (filter_item.minValue is not None and filter_item.minValue < 3):
            return ThreeDObjectsModel(object_ids=example_glbs_2)

    return ThreeDObjectsModel(object_ids=example_glbs_1)






# @router.post("/login")
# def login_user(user: UserLogin):
#     #check if user exists with email
#     print(user.email)
#     print(user.password)
#     user_db = db.query(User).filter(User.email == user.email).first()
#     if not user_db:
#         raise HTTPException(status_code=411, detail="no user with this email")

#     #check if password matches
#     is_match = bcrypt.checkpw(user.password.encode(), user_db.password)
    
#     if not is_match:
#         raise HTTPException(status_code=412, detail="mistyped password")


#     return user_db